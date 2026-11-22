"""
AIOps Diagnostic Engine for Robusta OSS on Amazon EKS.
Root Cause Analysis (RCA) and Autonomous Remediation Recommender.
Powered by Amazon Bedrock (Anthropic Claude 3.5 Sonnet / Haiku) with Local Deterministic Safety Fallback.
"""

import json
import logging
import os
from typing import Dict, Any, Optional

try:
    import boto3
    BEDROCK_AVAILABLE = True
except ImportError:
    BEDROCK_AVAILABLE = False

logger = logging.getLogger("robusta")

RCA_PROMPT_TEMPLATE = """You are an expert Principal SRE and Cloud Architect triaging a production Kubernetes incident on Amazon EKS.
Failure Mode Context: {failure_mode}
Target Workload: {target_workload} (Namespace: {namespace})
Alert Summary: {alert_summary}

Recent Pod Logs (Last 100 lines):
```
{pod_logs}
```

Recent Kubernetes Events:
```
{k8s_events}
```

Analyze the failure telemetry and output a strict JSON object with these exact keys:
1. "summary": A concise 1-2 sentence plain English explanation of what happened.
2. "root_cause": Clear identification of the technical root cause (e.g. socket deadlock, poison pill, token limit breach, OOMKill risk).
3. "confidence_score": Float between 0.0 and 1.0 indicating diagnostic confidence.
4. "recommended_action": Exactly one of ["ROLLOUT_RESTART", "DRAIN_DLQ_TO_QUARANTINE", "THROTTLE_BATCH_CONCURRENCY", "ESCALATE_TO_HUMAN"].
5. "idempotency_safe": Boolean indicating if the recommended action is 100% safe to run automatically.
6. "justification": Brief justification for the recommendation.

Ensure the output is ONLY valid JSON with no markdown formatting.
"""

class AIOpsDiagnostics:
    def __init__(
        self,
        provider: Optional[str] = None,
        region: str = "us-east-1",
        bedrock_model_id: str = "anthropic.claude-3-5-haiku-20241022-v1:0"
    ):
        self.provider = provider or os.environ.get("AIOPS_PROVIDER", "aws")
        self.region = region or os.environ.get("AWS_REGION", "us-east-1")
        self.bedrock_model_id = bedrock_model_id or os.environ.get("BEDROCK_MODEL_ID", "anthropic.claude-3-5-haiku-20241022-v1:0")
        self.bedrock_client = None

        if self.provider == "aws" and BEDROCK_AVAILABLE:
            try:
                self.bedrock_client = boto3.client("bedrock-runtime", region_name=self.region)
                logger.info(f"Initialized AWS Bedrock client in {self.region} with model {self.bedrock_model_id}")
            except Exception as e:
                logger.warning(f"Failed to initialize AWS Bedrock client: {e}. Will use deterministic fallback.")

    def analyze_incident(
        self,
        failure_mode: str,
        target_workload: str,
        namespace: str,
        alert_summary: str,
        pod_logs: str,
        k8s_events: str
    ) -> Dict[str, Any]:
        """
        Executes AI Root Cause Analysis via Amazon Bedrock. Returns structured JSON dictionary.
        """
        truncated_logs = pod_logs[-4000:] if len(pod_logs) > 4000 else pod_logs
        truncated_events = k8s_events[-2000:] if len(k8s_events) > 2000 else k8s_events

        prompt = RCA_PROMPT_TEMPLATE.format(
            failure_mode=failure_mode,
            target_workload=target_workload,
            namespace=namespace,
            alert_summary=alert_summary,
            pod_logs=truncated_logs,
            k8s_events=truncated_events
        )

        # 1. AWS Bedrock Inference
        if self.bedrock_client:
            try:
                native_request = {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 1000,
                    "temperature": 0.1,
                    "messages": [
                        {
                            "role": "user",
                            "content": prompt
                        }
                    ]
                }
                response = self.bedrock_client.invoke_model(
                    modelId=self.bedrock_model_id,
                    body=json.dumps(native_request)
                )
                response_body = json.loads(response["body"].read())
                raw_text = response_body["content"][0]["text"].strip()
                if raw_text.startswith("```json"):
                    raw_text = raw_text[7:]
                if raw_text.startswith("```"):
                    raw_text = raw_text[3:]
                if raw_text.endswith("```"):
                    raw_text = raw_text[:-3]
                result = json.loads(raw_text.strip())
                logger.info(f"AWS Bedrock RCA succeeded for {target_workload}: {result.get('recommended_action')}")
                return result
            except Exception as e:
                logger.error(f"Bedrock invocation failed: {e}. Executing deterministic fallback.")
                return self._deterministic_fallback(failure_mode, target_workload)

        # 2. Deterministic Safety Fallback (Minikube Local / Offline / Air-gapped)
        return self._deterministic_fallback(failure_mode, target_workload)

    def _deterministic_fallback(self, failure_mode: str, target_workload: str) -> Dict[str, Any]:
        """Safety fallback adhering to Zero-Hallucination & Confidently Wrong defense."""
        mode_upper = failure_mode.upper()
        if "STALLED" in mode_upper or "DEADLOCK" in mode_upper:
            return {
                "summary": f"Detected stalled message processing on {target_workload}. Pod is healthy according to K8s probes but processing zero stream events.",
                "root_cause": "Silent socket deadlock or thread starvation in stream consumer worker.",
                "confidence_score": 0.90,
                "recommended_action": "ROLLOUT_RESTART",
                "idempotency_safe": True,
                "justification": "Safe restart recovers deadlocked consumer thread without state corruption."
            }
        elif "DLQ" in mode_upper or "POISON" in mode_upper:
            return {
                "summary": f"Dead-letter queue backpressure detected for {target_workload}.",
                "root_cause": "Malformed payload schema or unhandled exception during message parsing in Amazon SQS.",
                "confidence_score": 0.88,
                "recommended_action": "DRAIN_DLQ_TO_QUARANTINE",
                "idempotency_safe": True,
                "justification": "Quarantining unparsable payloads to S3 prevents head-of-line blocking in SQS."
            }
        elif "QUOTA" in mode_upper or "429" in mode_upper or "THROTTLING" in mode_upper:
            return {
                "summary": f"AWS Bedrock / LLM API token quota exhausted (429 ThrottlingException) during batch processing.",
                "root_cause": "Transient Token-Per-Minute (TPM) burst exceeding AWS Bedrock account limit.",
                "confidence_score": 0.95,
                "recommended_action": "THROTTLE_BATCH_CONCURRENCY",
                "idempotency_safe": True,
                "justification": "Dynamic exponential backoff and worker throttling restores Bedrock compliance without dropped tasks."
            }
        return {
            "summary": f"Unclassified transient alert on {target_workload}.",
            "root_cause": "Telemetry inconclusive.",
            "confidence_score": 0.40,
            "recommended_action": "ESCALATE_TO_HUMAN",
            "idempotency_safe": False,
            "justification": "Ambiguous failure requires human engineer assessment."
        }
