import os
import uuid
from flask import Flask, jsonify, request
import boto3
from boto3.dynamodb.conditions import Key

app = Flask(__name__)
table = boto3.resource("dynamodb", region_name=os.getenv("AWS_REGION")).Table(os.environ["PRODUCTS_TABLE"])

@app.get("/")
def home():
    return jsonify({
        "application": "E-commerce Cloud AWS",
        "service": "catalog",
        "message": "Microsserviço de catálogo disponível",
        "endpoints": ["/health", "/products"]
    })

@app.get("/health")
def health():
    return jsonify({"status": "healthy", "service": "catalog"})

@app.get("/products")
def list_products():
    result = table.scan(Limit=100)
    return jsonify(result.get("Items", []))

@app.post("/products")
def create_product():
    data = request.get_json(silent=True) or {}
    if not data.get("name") or data.get("price") is None:
        return jsonify({"error": "Informe name e price"}), 400
    item = {
        "product_id": str(uuid.uuid4()),
        "name": str(data["name"]),
        "price": str(data["price"]),
        "description": str(data.get("description", ""))
    }
    table.put_item(Item=item)
    return jsonify(item), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
