# -*- coding: utf-8 -*-

"""FastAPI Endpoints for Payment & PayOS VietQR Webhook.

Endpoints:
- POST /api/payment/payos-webhook: Webhook nhận thông báo thanh toán tức thì từ PayOS (NAPAS 24/7)
- POST /api/payment/create-payment-link: Tạo link thanh toán PayOS từ server
- GET /api/payment/order-status/{order_code}: Kiểm tra trạng thái đơn hàng
- POST /api/payment/simulate-webhook: Test giả lập webhook trong môi trường dev
"""

from fastapi import APIRouter, Request, HTTPException, status
from pydantic import BaseModel
from typing import Optional, Dict, Any
import logging

from services.payos_service import payos_service, get_firestore_doc

logger = logging.getLogger("PaymentEndpoints")
router = APIRouter(prefix="/api/payment", tags=["Payment"])

# MARK: - Request / Response Models
class CreatePaymentLinkRequest(BaseModel):
    orderCode: int
    amount: int
    description: str
    returnUrl: Optional[str] = "applearnenglish://payment-success"
    cancelUrl: Optional[str] = "applearnenglish://payment-cancel"

class SimulateWebhookRequest(BaseModel):
    orderCode: int
    amount: int
    uid: str
    planKey: str = "yearly"

# MARK: - Webhook Endpoint từ PayOS
@router.post("/payos-webhook")
async def payos_webhook(request: Request):
    """Webhook nhận thông báo biến động số dư / thanh toán thành công từ PayOS.
    
    Khi người dùng quét mã VietQR và ngân hàng chuyển khoản thành công,
    PayOS sẽ gọi đến endpoint này kèm chữ ký số HMAC-SHA256 để xác thực.
    Sau khi xác thực, hệ thống tự động kích hoạt gói VIP cho user trong Firestore.
    """
    try:
        payload = await request.json()
        logger.info(f"PayOS Webhook received: {payload}")
    except Exception as e:
        logger.error(f"Invalid JSON payload: {e}")
        return {"code": "01", "desc": "Invalid JSON", "data": None}

    # Xử lý webhook và cập nhật Firestore
    result = payos_service.process_webhook(payload)
    
    if not result.get("success", False):
        logger.warning(f"Webhook processing failed or invalid signature: {result.get('message')}")
        # Vẫn trả code theo chuẩn PayOS hoặc trả lỗi
        return {"code": "01", "desc": result.get("message", "Failed"), "data": None}

    logger.info(f"Successfully processed payment for order {result.get('orderCode')}. User VIP activated: {result.get('activatedVIP')}")
    
    # PayOS yêu cầu response chuẩn HTTP 200 dạng:
    return {
        "code": "00",
        "desc": "success",
        "data": {
            "orderCode": result.get("orderCode"),
            "activatedVIP": result.get("activatedVIP")
        }
    }

# MARK: - Tạo Payment Link từ Backend
@router.post("/create-payment-link")
async def create_payment_link(req: CreatePaymentLinkRequest):
    """Tạo link thanh toán PayOS qua v2 API."""
    try:
        res = payos_service.create_payment_link(
            order_code=req.orderCode,
            amount=req.amount,
            description=req.description,
            return_url=req.returnUrl,
            cancel_url=req.cancelUrl
        )
        return res
    except Exception as e:
        logger.error(f"Error creating payment link: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"PayOS error: {str(e)}"
        )

# MARK: - Kiểm tra trạng thái đơn hàng
@router.get("/order-status/{order_code}")
async def check_order_status(order_code: int):
    """Kiểm tra trạng thái đơn hàng trong collection 'payment_orders'."""
    doc = get_firestore_doc("payment_orders", str(order_code))
    if not doc:
        return {
            "orderCode": order_code,
            "status": "NOT_FOUND"
        }
    return {
        "orderCode": order_code,
        "status": doc.get("status", "PENDING"),
        "uid": doc.get("uid"),
        "planKey": doc.get("planKey")
    }

# MARK: - Endpoint Test / Giả lập Webhook cho Dev
@router.post("/simulate-webhook")
async def simulate_webhook(req: SimulateWebhookRequest):
    """Endpoint dành cho nhà phát triển test luồng thanh toán mà không cần chuyển tiền thật."""
    mock_payload = {
        "code": "00",
        "desc": "success",
        "data": {
            "orderCode": req.orderCode,
            "amount": req.amount,
            "description": f"PRO {req.uid[:6].upper()}",
            "accountNumber": "0339998888",
            "reference": "TEST_FT_123456",
            "transactionDateTime": "2026-11-04 13:30:00",
            "currency": "VND",
            "code": "00",
            "desc": "Thanh toan don hang test thanh cong"
        },
        "signature": "mock_test_signature"
    }
    
    # Kích hoạt trực tiếp
    result = payos_service.process_webhook(mock_payload)
    return {
        "status": "success",
        "message": "Simulated PayOS payment webhook processed successfully.",
        "result": result
    }
