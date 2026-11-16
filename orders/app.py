import json
import os
import uuid
from datetime import datetime, timezone
from flask import Flask, jsonify, request
import boto3

app = Flask(__name__)
region = os.getenv("AWS_REGION")
dynamodb = boto3.resource("dynamodb", region_name=region)
orders_table = dynamodb.Table(os.environ["ORDERS_TABLE"])
sqs = boto3.client("sqs", region_name=region)
queue_url = os.environ["ORDERS_QUEUE_URL"]

@app.get("/")
def home():
    return jsonify({
        "application": "E-commerce Cloud AWS",
        "service": "orders",
        "message": "Microsserviço de pedidos disponível",
        "endpoints": ["/health", "/orders"]
    })

@app.get("/health")
def health():
    return jsonify({"status": "healthy", "service": "orders"})

@app.get("/orders")
def list_orders():
    result = orders_table.scan(Limit=100)
    return jsonify(result.get("Items", []))

@app.post("/orders")
def create_order():
    data = request.get_json(silent=True) or {}
    if not data.get("product_id") or not data.get("quantity"):
        return jsonify({"error": "Informe product_id e quantity"}), 400
    try:
        quantity = int(data["quantity"])
        if quantity < 1:
            raise ValueError()
    except (TypeError, ValueError):
        return jsonify({"error": "quantity deve ser um inteiro positivo"}), 400

    order = {
        "order_id": str(uuid.uuid4()),
        "product_id": str(data["product_id"]),
        "quantity": quantity,
        "customer": str(data.get("customer", "não informado")),
        "status": "RECEIVED",
        "created_at": datetime.now(timezone.utc).isoformat()
    }
    orders_table.put_item(Item=order)
    sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps(order, ensure_ascii=False)
    )
    return jsonify({"message": "Pedido recebido e enviado para processamento assíncrono", "order": order}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
