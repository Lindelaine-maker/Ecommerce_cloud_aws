import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    processed = 0
    for record in event.get("Records", []):
        try:
            order = json.loads(record["body"])
            logger.info(
                "PEDIDO_PROCESSADO order_id=%s product_id=%s quantity=%s",
                order.get("order_id"),
                order.get("product_id"),
                order.get("quantity")
            )
            processed += 1
        except Exception:
            logger.exception("Falha ao processar mensagem SQS")
            raise
    logger.info("Total de mensagens processadas: %s", processed)
    return {"statusCode": 200, "processed": processed}
