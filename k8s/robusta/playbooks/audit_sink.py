"""
Immutable Audit Sink for Robusta OSS.
Records every automated diagnosis, prompt interaction, and execution event.
Supports Amazon DynamoDB (AWS EKS Production) with local JSONL/stdout fallback for Minikube local testing.
"""

import datetime
import json
import logging
import os
import tempfile
import uuid
from typing import Dict, Any, Optional

try:
    import boto3
    BOTO3_AVAILABLE = True
except ImportError:
    BOTO3_AVAILABLE = False

logger = logging.getLogger("robusta")

class AuditLogger:
    def __init__(
        self,
        table_name: str = "omnipulse_remediation_audit",
        region: str = "us-east-1",
        local_log_path: Optional[str] = None
    ):
        self.table_name = os.environ.get("DYNAMODB_AUDIT_TABLE", table_name)
        self.region = os.environ.get("AWS_REGION", region)
        self.local_log_path = local_log_path or os.path.join(tempfile.gettempdir(), "omnipulse_audit.jsonl")
        self.dynamodb_table = None

        if BOTO3_AVAILABLE and os.environ.get("AWS_EXECUTION_ENV") or os.environ.get("AWS_REGION"):
            try:
                dynamodb = boto3.resource("dynamodb", region_name=self.region)
                self.dynamodb_table = dynamodb.Table(self.table_name)
                logger.info(f"Initialized DynamoDB Audit client for table: {self.table_name} in {self.region}")
            except Exception as e:
                logger.warning(f"Could not connect to DynamoDB: {e}. Falling back to local file and stdout.")

    def log_remediation_event(
        self,
        failure_mode: str,
        target_workload: str,
        diagnosis_summary: str,
        action_executed: str,
        execution_type: str = "AUTOMATED",
        operator: Optional[str] = None,
        status: str = "SUCCESS",
        raw_telemetry: Optional[str] = None,
        incident_id: Optional[str] = None
    ) -> bool:
        """
        Inserts a structured row into DynamoDB table or local audit file.
        """
        now_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()
        record = {
            "incident_id": incident_id or str(uuid.uuid4()),
            "timestamp": now_iso,
            "failure_mode": failure_mode,
            "target_workload": target_workload,
            "diagnosis_summary": diagnosis_summary,
            "action_executed": action_executed,
            "execution_type": execution_type,
            "operator": operator or ("SYSTEM_ROBUSTA" if execution_type == "AUTOMATED" else "ON_CALL_OPERATOR"),
            "status": status,
            "raw_telemetry": raw_telemetry or ""
        }

        # 1. Try writing to DynamoDB
        if self.dynamodb_table:
            try:
                self.dynamodb_table.put_item(Item=record)
                logger.info(f"Audit record persisted to DynamoDB for incident {record['incident_id']}")
                return True
            except Exception as e:
                logger.error(f"Failed to write audit record to DynamoDB: {e}. Writing to local fallback.")

        # 2. Local Fallback (Minikube / Local Testing)
        try:
            with open(self.local_log_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record) + "\n")
            logger.info(f"Audit record appended to {self.local_log_path} for incident {record['incident_id']}")
        except Exception as e:
            logger.warning(f"Could not write audit record to file: {e}")

        logger.info(f"[AUDIT LOG] {json.dumps(record)}")
        return True
