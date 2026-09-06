#!/bin/bash
set -euo pipefail

: "${CLUSTER:?}"
: "${TASKDEF:?}"
: "${SUBNET:?}"
: "${SG:?}"
: "${WORLD:?}"

echo "Starting world '${WORLD}' on cluster '${CLUSTER}'..."

TASK_ARN=$(aws ecs run-task \
  --cluster "${CLUSTER}" \
  --task-definition "${TASKDEF}" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNET}],securityGroups=[${SG}],assignPublicIp=ENABLED}" \
  --overrides "{\"containerOverrides\":[{\"name\":\"valheim\",\"environment\":[{\"name\":\"WORLD\",\"value\":\"${WORLD}\"}]}]}" \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Task: ${TASK_ARN}"
echo "Waiting for ENI..."

ENI_ID=""
for _ in $(seq 1 30); do
  ENI_ID=$(aws ecs describe-tasks \
    --cluster "${CLUSTER}" \
    --tasks "${TASK_ARN}" \
    --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value | [0]" \
    --output text 2>/dev/null || true)
  [ -n "${ENI_ID}" ] && [ "${ENI_ID}" != "None" ] && break
  sleep 2
done

if [ -z "${ENI_ID}" ] || [ "${ENI_ID}" = "None" ]; then
  echo "Timed out waiting for ENI" >&2
  exit 1
fi

echo "Task started (check console for public IP)"
