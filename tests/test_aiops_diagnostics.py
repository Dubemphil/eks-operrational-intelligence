"""
Unit tests for AIOps Diagnostics Engine and Audit Sink.
Validates zero-hallucination guardrails and deterministic incident triage.
"""

import json
import os
import sys
import tempfile
import unittest

# Ensure src/robusta-playbooks is on sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src", "robusta-playbooks")))

from aiops_diagnostics import AIOpsDiagnostics
from audit_sink import AuditLogger

class TestAIOpsDiagnostics(unittest.TestCase):
    def setUp(self):
        # Force local/deterministic provider for unit tests
        os.environ["AIOPS_PROVIDER"] = "local"
        self.diagnostics = AIOpsDiagnostics(provider="local")
        self.test_audit_file = os.path.join(tempfile.gettempdir(), "test_audit.jsonl")
        self.audit_logger = AuditLogger(local_log_path=self.test_audit_file)

    def tearDown(self):
        if os.path.exists(self.test_audit_file):
            try:
                os.remove(self.test_audit_file)
            except OSError:
                pass

    def test_stalled_consumer_deadlock_triage(self):
        rca = self.diagnostics.analyze_incident(
            failure_mode="STALLED_CONSUMER_DEADLOCK",
            target_workload="emailservice",
            namespace="omnipulse-local",
            alert_summary="Consumer thread hung. 0 messages acked in 120s.",
            pod_logs="[ERROR] SocketTimeout: Transport stream read timed out.",
            k8s_events="Normal Scheduled, Pod is marked Running 1/1"
        )
        self.assertIn("summary", rca)
        self.assertEqual(rca["recommended_action"], "ROLLOUT_RESTART")
        self.assertTrue(rca["idempotency_safe"])
        self.assertGreaterEqual(rca["confidence_score"], 0.8)

    def test_dlq_poison_pill_triage(self):
        rca = self.diagnostics.analyze_incident(
            failure_mode="DLQ_POISON_PILL",
            target_workload="consumer-triage-dlq",
            namespace="sqs",
            alert_summary="DLQ message surge detected (> 100 messages).",
            pod_logs="SchemaValidationError: Missing required field 'order_id'",
            k8s_events="Alarm triggered"
        )
        self.assertEqual(rca["recommended_action"], "DRAIN_DLQ_TO_QUARANTINE")
        self.assertTrue(rca["idempotency_safe"])
        self.assertGreaterEqual(rca["confidence_score"], 0.8)

    def test_quota_throttling_triage(self):
        rca = self.diagnostics.analyze_incident(
            failure_mode="BEDROCK_QUOTA_EXHAUSTED",
            target_workload="paymentservice",
            namespace="omnipulse-local",
            alert_summary="AWS Bedrock HTTP 429 ThrottlingException",
            pod_logs="ThrottlingException: Rate exceeded for invoke_model",
            k8s_events="429 error rate threshold exceeded"
        )
        self.assertEqual(rca["recommended_action"], "THROTTLE_BATCH_CONCURRENCY")
        self.assertTrue(rca["idempotency_safe"])

    def test_audit_logger_local_persistence(self):
        success = self.audit_logger.log_remediation_event(
            failure_mode="STALLED_CONSUMER_DEADLOCK",
            target_workload="emailservice",
            diagnosis_summary="Consumer hung, safely restarted",
            action_executed="ROLLOUT_RESTART",
            execution_type="AUTOMATED",
            status="SUCCESS"
        )
        self.assertTrue(success)
        self.assertTrue(os.path.exists(self.test_audit_file))
        with open(self.test_audit_file, "r") as f:
            lines = f.readlines()
            self.assertEqual(len(lines), 1)
            record = json.loads(lines[0])
            self.assertEqual(record["target_workload"], "emailservice")
            self.assertEqual(record["action_executed"], "ROLLOUT_RESTART")

if __name__ == "__main__":
    unittest.main()
