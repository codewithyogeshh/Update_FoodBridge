#!/usr/bin/env python3
"""
Generates clean, high-resolution engineering diagram graphics for FoodBridge:
1. DFD Level 0 Context Diagram
2. Use Case Diagram
3. Sequence Diagram (Dual-OTP Handover)
4. ER Diagram (Entity-Relationship Database Model - Clean Orthogonal Layout)
"""

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 800
BG_COLOR = (255, 255, 255)
WHITE = (255, 255, 255)
BRAND_GREEN = (5, 150, 105)
BRAND_GREEN_BG = (236, 253, 245)
NAVY_BLUE = (15, 23, 42)
TEXT_DARK = (15, 23, 42)
TEXT_MUTED = (71, 85, 105)
BORDER_GRAY = (203, 213, 225)
ACCENT_BLUE = (37, 99, 235)
ACCENT_BLUE_BG = (239, 246, 255)
ACCENT_AMBER = (217, 119, 6)
ACCENT_AMBER_BG = (254, 243, 199)
ACCENT_PURPLE = (124, 58, 237)
ACCENT_PURPLE_BG = (243, 232, 255)

FONT_REG = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 16)
FONT_BOLD = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 18)
FONT_SM_BOLD = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 14)
FONT_SM_REG = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 13)
FONT_TITLE = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 22)

def draw_arrow(draw, start, end, color=(71, 85, 105), width=2, arrow_size=10):
    x1, y1 = start
    x2, y2 = end
    draw.line([x1, y1, x2, y2], fill=color, width=width)
    angle = math.atan2(y2 - y1, x2 - x1)
    p1 = (x2 - arrow_size * math.cos(angle - math.pi / 6),
          y2 - arrow_size * math.sin(angle - math.pi / 6))
    p2 = (x2 - arrow_size * math.cos(angle + math.pi / 6),
          y2 - arrow_size * math.sin(angle + math.pi / 6))
    draw.polygon([ (x2, y2), p1, p2 ], fill=color)

def generate_dfd_l0(out_path):
    img = Image.new("RGB", (W, H), color=BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Frame border
    draw.rounded_rectangle([10, 10, W - 10, H - 10], radius=16, fill=WHITE, outline=BORDER_GRAY, width=2)

    # Title
    draw.text((W // 2, 45), "Data Flow Diagram: Level 0 (Context Diagram)", fill=TEXT_DARK, font=FONT_TITLE, anchor="mm")
    draw.text((W // 2, 75), "Single process interacting with 4 key external entities across surplus food relief", fill=TEXT_MUTED, font=FONT_REG, anchor="mm")

    # Central Process Circle
    cx, cy, cr = 600, 420, 110
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=BRAND_GREEN_BG, outline=BRAND_GREEN, width=3)
    draw.text((cx, cy - 35), "0.0", fill=BRAND_GREEN, font=FONT_BOLD, anchor="mm")
    draw.text((cx, cy - 10), "FOODBRIDGE", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((cx, cy + 15), "Relief Logistics", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((cx, cy + 40), "Engine", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")

    # 4 External Entities
    d_box = [80, 160, 320, 240]
    draw.rounded_rectangle(d_box, radius=8, fill=(241, 245, 249), outline=NAVY_BLUE, width=2)
    draw.text((200, 185), "DONOR", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((200, 215), "(Hotel / Hostel / Banquet)", fill=TEXT_MUTED, font=FONT_SM_REG, anchor="mm")

    s_box = [880, 160, 1120, 240]
    draw.rounded_rectangle(s_box, radius=8, fill=(241, 245, 249), outline=NAVY_BLUE, width=2)
    draw.text((1000, 185), "SHELTER (NGO)", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((1000, 215), "(Verified Darpan Recipient)", fill=TEXT_MUTED, font=FONT_SM_REG, anchor="mm")

    v_box = [80, 600, 320, 680]
    draw.rounded_rectangle(v_box, radius=8, fill=(241, 245, 249), outline=NAVY_BLUE, width=2)
    draw.text((200, 625), "VOLUNTEER COURIER", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((200, 655), "(Grassroots Dispatch)", fill=TEXT_MUTED, font=FONT_SM_REG, anchor="mm")

    a_box = [880, 600, 1120, 680]
    draw.rounded_rectangle(a_box, radius=8, fill=(241, 245, 249), outline=NAVY_BLUE, width=2)
    draw.text((1000, 625), "SYSTEM ADMIN", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((1000, 655), "(Governance & Telemetry)", fill=TEXT_MUTED, font=FONT_SM_REG, anchor="mm")

    # Flows
    draw_arrow(draw, (320, 190), (510, 350), color=BRAND_GREEN, width=2)
    draw.text((390, 250), "1. Listing details (quantity, expiry)", fill=BRAND_GREEN, font=FONT_SM_BOLD, anchor="rm")

    draw_arrow(draw, (500, 380), (320, 220), color=ACCENT_BLUE, width=2)
    draw.text((390, 310), "2. Listing ID & Pickup OTP", fill=ACCENT_BLUE, font=FONT_SM_BOLD, anchor="rm")

    draw_arrow(draw, (880, 190), (690, 350), color=BRAND_GREEN, width=2)
    draw.text((810, 250), "3. Darpan ID & Claim Request", fill=BRAND_GREEN, font=FONT_SM_BOLD, anchor="lm")

    draw_arrow(draw, (700, 380), (880, 220), color=ACCENT_BLUE, width=2)
    draw.text((810, 310), "4. Approved Notice & Delivery OTP", fill=ACCENT_BLUE, font=FONT_SM_BOLD, anchor="lm")

    draw_arrow(draw, (320, 620), (500, 470), color=BRAND_GREEN, width=2)
    draw.text((390, 530), "5. Task Accept & Entered OTPs", fill=BRAND_GREEN, font=FONT_SM_BOLD, anchor="rm")

    draw_arrow(draw, (510, 495), (320, 650), color=ACCENT_BLUE, width=2)
    draw.text((390, 590), "6. Dispatch Route & Navigation", fill=ACCENT_BLUE, font=FONT_SM_BOLD, anchor="rm")

    draw_arrow(draw, (880, 620), (700, 470), color=BRAND_GREEN, width=2)
    draw.text((810, 530), "7. NGO Accreditation Decisions", fill=BRAND_GREEN, font=FONT_SM_BOLD, anchor="lm")

    draw_arrow(draw, (690, 495), (880, 650), color=ACCENT_BLUE, width=2)
    draw.text((810, 590), "8. Real-time KPIs & Audit Logs", fill=ACCENT_BLUE, font=FONT_SM_BOLD, anchor="lm")

    img.save(out_path, quality=95)
    print(f"[OK] Generated: {out_path}")

def generate_use_case(out_path):
    img = Image.new("RGB", (W, H), color=BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Frame border
    draw.rounded_rectangle([10, 10, W - 10, H - 10], radius=16, fill=WHITE, outline=BORDER_GRAY, width=2)

    # Title
    draw.text((W // 2, 40), "Use Case Diagram: System Boundary & Primary Actors", fill=TEXT_DARK, font=FONT_TITLE, anchor="mm")

    # Boundary
    draw.rounded_rectangle([320, 80, 880, 760], radius=12, fill=(250, 250, 250), outline=BORDER_GRAY, width=2)
    draw.text((600, 105), "FOODBRIDGE SYSTEM BOUNDARY", fill=BRAND_GREEN, font=FONT_SM_BOLD, anchor="mm")

    # Actors
    draw.rounded_rectangle([40, 160, 240, 240], radius=8, fill=BRAND_GREEN_BG, outline=BRAND_GREEN, width=2)
    draw.text((140, 185), "Donor", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((140, 215), "(Hotel / Hostel)", fill=TEXT_MUTED, font=FONT_SM_REG, anchor="mm")

    draw.rounded_rectangle([40, 520, 240, 600], radius=8, fill=ACCENT_BLUE_BG, outline=ACCENT_BLUE, width=2)
    draw.text((140, 545), "Shelter (NGO)", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((140, 575), "(Verified Recipient)", fill=TEXT_MUTED, font=FONT_SM_REG, anchor="mm")

    draw.rounded_rectangle([960, 160, 1160, 240], radius=8, fill=ACCENT_AMBER_BG, outline=ACCENT_AMBER, width=2)
    draw.text((1060, 185), "Volunteer Courier", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((1060, 215), "(Field Dispatch)", fill=TEXT_MUTED, font=FONT_SM_REG, anchor="mm")

    draw.rounded_rectangle([960, 520, 1160, 600], radius=8, fill=ACCENT_PURPLE_BG, outline=ACCENT_PURPLE, width=2)
    draw.text((1060, 545), "System Admin", fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
    draw.text((1060, 575), "(Platform Governance)", fill=TEXT_MUTED, font=FONT_SM_REG, anchor="mm")

    use_cases = [
        ("UC-01: Login & 2FA Auth", 155),
        ("UC-02: Declare Surplus Food", 225),
        ("UC-03: <<include>> Sign Safety Charter", 295),
        ("UC-04: Submit Darpan / 80G Docs", 365),
        ("UC-05: Reserve Claim by Portions", 435),
        ("UC-06: Accept Courier Dispatch", 505),
        ("UC-07: Validate Pickup OTP", 575),
        ("UC-08: Validate Delivery OTP", 645),
        ("UC-09: Inspect Live KPIs & Audit Logs", 715)
    ]
    for text, y in use_cases:
        is_sub = "include" in text
        fill_col = (240, 253, 244) if not is_sub else (254, 243, 199)
        out_col = BRAND_GREEN if not is_sub else ACCENT_AMBER
        draw.rounded_rectangle([400, y - 20, 800, y + 20], radius=20, fill=fill_col, outline=out_col, width=1)
        draw.text((600, y), text, fill=TEXT_DARK, font=FONT_SM_BOLD, anchor="mm")

    draw.line([240, 200, 400, 155], fill=TEXT_MUTED, width=1)
    draw.line([240, 200, 400, 225], fill=TEXT_MUTED, width=1)
    draw.line([600, 245, 600, 275], fill=ACCENT_AMBER, width=2)

    draw.line([240, 560, 400, 155], fill=TEXT_MUTED, width=1)
    draw.line([240, 560, 400, 365], fill=TEXT_MUTED, width=1)
    draw.line([240, 560, 400, 435], fill=TEXT_MUTED, width=1)
    draw.line([240, 560, 400, 645], fill=TEXT_MUTED, width=1)

    draw.line([960, 200, 800, 155], fill=TEXT_MUTED, width=1)
    draw.line([960, 200, 800, 505], fill=TEXT_MUTED, width=1)
    draw.line([960, 200, 800, 575], fill=TEXT_MUTED, width=1)
    draw.line([960, 200, 800, 645], fill=TEXT_MUTED, width=1)

    draw.line([960, 560, 800, 155], fill=TEXT_MUTED, width=1)
    draw.line([960, 560, 800, 365], fill=TEXT_MUTED, width=1)
    draw.line([960, 560, 800, 715], fill=TEXT_MUTED, width=1)

    img.save(out_path, quality=95)
    print(f"[OK] Generated: {out_path}")

def generate_sequence(out_path):
    img = Image.new("RGB", (W, H), color=BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Frame border
    draw.rounded_rectangle([10, 10, W - 10, H - 10], radius=16, fill=WHITE, outline=BORDER_GRAY, width=2)

    # Title
    draw.text((W // 2, 40), "Sequence Diagram: Real-Time Dual-OTP Handover Lifecycle", fill=TEXT_DARK, font=FONT_TITLE, anchor="mm")

    cols = [
        ("Donor Client", 180, BRAND_GREEN_BG, BRAND_GREEN),
        ("Supabase Cloud / DB", 460, ACCENT_BLUE_BG, ACCENT_BLUE),
        ("Volunteer App", 740, ACCENT_AMBER_BG, ACCENT_AMBER),
        ("Shelter (NGO) App", 1020, ACCENT_PURPLE_BG, ACCENT_PURPLE)
    ]
    for title, x, bg_c, out_c in cols:
        draw.rounded_rectangle([x - 85, 80, x + 85, 125], radius=8, fill=bg_c, outline=out_c, width=2)
        draw.text((x, 102), title, fill=NAVY_BLUE, font=FONT_BOLD, anchor="mm")
        for y in range(135, 745, 15):
            draw.line([x, y, x, y + 8], fill=BORDER_GRAY, width=2)

    flows = [
        (180, 460, 175, "1. postSurplus(meals, expiry) -> creates listing", BRAND_GREEN),
        (460, 180, 235, "2. returnPickupOTP(hash) -> display on donor phone", ACCENT_BLUE),
        (460, 740, 295, "3. WebSocket push: new_donation_broadcast (<80ms)", ACCENT_AMBER),
        (460, 1020, 355, "4. WebSocket push: incoming_surplus_alert", ACCENT_PURPLE),
        (1020, 460, 415, "5. reserveClaim(portions) -> generate delivery OTP", ACCENT_PURPLE),
        (740, 460, 475, "6. acceptDispatchTask() -> lock courier assignment", ACCENT_AMBER),
        (740, 460, 540, "7. verifyPickupOTP(otp) -> status -> IN_TRANSIT", BRAND_GREEN),
        (1020, 460, 605, "8. verifyDeliveryOTP(otp) -> status -> DELIVERED", ACCENT_BLUE),
        (460, 460, 675, "9. recordImmutableAuditLog(timestamp, hashes, IDs)", NAVY_BLUE)
    ]

    for x1, x2, y, msg, colr in flows:
        if x1 == x2:
            draw.rectangle([x1 - 10, y - 10, x1 + 10, y + 25], fill=(226, 232, 240), outline=NAVY_BLUE)
            draw.line([x1, y - 5, x1 + 40, y - 5], fill=NAVY_BLUE, width=2)
            draw.line([x1 + 40, y - 5, x1 + 40, y + 20], fill=NAVY_BLUE, width=2)
            draw_arrow(draw, (x1 + 40, y + 20), (x1 + 12, y + 20), color=NAVY_BLUE, width=2)
            draw.text((x1 + 50, y + 5), msg, fill=NAVY_BLUE, font=FONT_SM_BOLD, anchor="lm")
        else:
            draw_arrow(draw, (x1, y), (x2, y), color=colr, width=2)
            mid_x = (x1 + x2) // 2
            draw.text((mid_x, y - 12), msg, fill=colr, font=FONT_SM_BOLD, anchor="mm")

    img.save(out_path, quality=95)
    print(f"[OK] Generated: {out_path}")

def generate_er(out_path):
    img = Image.new("RGB", (W, H), color=BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Frame border
    draw.rounded_rectangle([10, 10, W - 10, H - 10], radius=16, fill=WHITE, outline=BORDER_GRAY, width=2)

    # Title
    draw.text((W // 2, 40), "Database Schema: Entity Relationship (ER) Model", fill=TEXT_DARK, font=FONT_TITLE, anchor="mm")

    # Table 1: USERS (Top Left)
    u_box = [60, 80, 480, 360]
    draw.rounded_rectangle(u_box, radius=8, fill=WHITE, outline=BRAND_GREEN, width=2)
    draw.rectangle([60, 80, 480, 115], fill=BRAND_GREEN)
    draw.text((270, 97), "USERS (Profiles & Authentication)", fill=WHITE, font=FONT_BOLD, anchor="mm")
    u_fields = [
        ("PK", "id", "UUID (auth.users)"),
        (" ", "email", "VARCHAR(255) UNIQUE"),
        (" ", "role", "ENUM(donor, vol, ngo, admin)"),
        (" ", "full_name", "VARCHAR(100)"),
        (" ", "phone_number", "VARCHAR(15)"),
        (" ", "is_verified", "BOOLEAN DEFAULT FALSE"),
        (" ", "created_at", "TIMESTAMPTZ DEFAULT NOW()")
    ]
    for i, (k, col, typ) in enumerate(u_fields):
        y = 135 + i * 28
        draw.text((80, y), k, fill=ACCENT_AMBER if k == "PK" else TEXT_MUTED, font=FONT_SM_BOLD)
        draw.text((120, y), col, fill=TEXT_DARK, font=FONT_SM_BOLD)
        draw.text((310, y), typ, fill=TEXT_MUTED, font=FONT_SM_REG)

    # Table 2: DONATIONS (Top Right)
    d_box = [720, 80, 1140, 390]
    draw.rounded_rectangle(d_box, radius=8, fill=WHITE, outline=ACCENT_BLUE, width=2)
    draw.rectangle([720, 80, 1140, 115], fill=ACCENT_BLUE)
    draw.text((930, 97), "DONATIONS (Surplus Postings)", fill=WHITE, font=FONT_BOLD, anchor="mm")
    d_fields = [
        ("PK", "id", "UUID DEFAULT gen_random_uuid()"),
        ("FK", "donor_id", "UUID -> users.id"),
        (" ", "food_type", "VARCHAR(50) NOT NULL"),
        (" ", "quantity_kg", "NUMERIC(6,2) NOT NULL"),
        (" ", "expiry_timestamp", "TIMESTAMPTZ NOT NULL"),
        (" ", "pickup_otp_hash", "VARCHAR(64) NOT NULL"),
        (" ", "status", "ENUM(available, claimed, delivered)"),
        (" ", "created_at", "TIMESTAMPTZ DEFAULT NOW()")
    ]
    for i, (k, col, typ) in enumerate(d_fields):
        y = 135 + i * 28
        draw.text((740, y), k, fill=ACCENT_AMBER if "K" in k else TEXT_MUTED, font=FONT_SM_BOLD)
        draw.text((780, y), col, fill=TEXT_DARK, font=FONT_SM_BOLD)
        draw.text((970, y), typ, fill=TEXT_MUTED, font=FONT_SM_REG)

    # Table 3: DELIVERIES (Bottom Right)
    del_box = [720, 460, 1140, 740]
    draw.rounded_rectangle(del_box, radius=8, fill=WHITE, outline=ACCENT_AMBER, width=2)
    draw.rectangle([720, 460, 1140, 495], fill=ACCENT_AMBER)
    draw.text((930, 477), "DELIVERIES (Logistics Handover)", fill=WHITE, font=FONT_BOLD, anchor="mm")
    del_fields = [
        ("PK", "id", "UUID DEFAULT gen_random_uuid()"),
        ("FK", "donation_id", "UUID -> donations.id"),
        ("FK", "volunteer_id", "UUID -> users.id"),
        ("FK", "recipient_ngo_id", "UUID -> users.id"),
        (" ", "claimed_at", "TIMESTAMPTZ NOT NULL"),
        (" ", "picked_up_at", "TIMESTAMPTZ"),
        (" ", "delivered_at", "TIMESTAMPTZ"),
        (" ", "delivery_otp_hash", "VARCHAR(64) NOT NULL")
    ]
    for i, (k, col, typ) in enumerate(del_fields):
        y = 515 + i * 26
        draw.text((740, y), k, fill=ACCENT_AMBER if "K" in k else TEXT_MUTED, font=FONT_SM_BOLD)
        draw.text((780, y), col, fill=TEXT_DARK, font=FONT_SM_BOLD)
        draw.text((970, y), typ, fill=TEXT_MUTED, font=FONT_SM_REG)

    # Table 4: AUDIT_LOGS (Bottom Left)
    a_box = [60, 460, 480, 740]
    draw.rounded_rectangle(a_box, radius=8, fill=WHITE, outline=ACCENT_PURPLE, width=2)
    draw.rectangle([60, 460, 480, 495], fill=ACCENT_PURPLE)
    draw.text((270, 477), "AUDIT_LOGS (Immutable Governance)", fill=WHITE, font=FONT_BOLD, anchor="mm")
    a_fields = [
        ("PK", "id", "BIGSERIAL"),
        ("FK", "actor_id", "UUID -> users.id"),
        (" ", "action", "VARCHAR(50) NOT NULL"),
        (" ", "entity_id", "UUID NOT NULL"),
        (" ", "timestamp", "TIMESTAMPTZ DEFAULT NOW()"),
        (" ", "ip_address_hash", "VARCHAR(64)"),
        (" ", "metadata", "JSONB structured payload")
    ]
    for i, (k, col, typ) in enumerate(a_fields):
        y = 520 + i * 28
        draw.text((80, y), k, fill=ACCENT_AMBER if "K" in k else TEXT_MUTED, font=FONT_SM_BOLD)
        draw.text((120, y), col, fill=TEXT_DARK, font=FONT_SM_BOLD)
        draw.text((310, y), typ, fill=TEXT_MUTED, font=FONT_SM_REG)

    # Clean Orthogonal Connectors
    # 1. USERS -> DONATIONS (Horizontal top)
    draw_arrow(draw, (480, 200), (720, 200), color=BRAND_GREEN, width=2)
    draw.text((600, 185), "1 : N (Submits)", fill=BRAND_GREEN, font=FONT_SM_BOLD, anchor="mm")

    # 2. DONATIONS -> DELIVERIES (Vertical right)
    draw_arrow(draw, (930, 390), (930, 460), color=ACCENT_BLUE, width=2)
    draw.text((980, 425), "1 : 1 (Dispatches)", fill=ACCENT_BLUE, font=FONT_SM_BOLD, anchor="lm")

    # 3. USERS -> AUDIT_LOGS (Vertical left)
    draw_arrow(draw, (270, 360), (270, 460), color=ACCENT_PURPLE, width=2)
    draw.text((220, 410), "1 : N (Audits)", fill=ACCENT_PURPLE, font=FONT_SM_BOLD, anchor="rm")

    # 4. USERS -> DELIVERIES (Orthogonal link across)
    draw_arrow(draw, (480, 260), (720, 560), color=TEXT_MUTED, width=2)
    draw.text((600, 400), "1 : N (Fulfills)", fill=TEXT_MUTED, font=FONT_SM_BOLD, anchor="mm")

    img.save(out_path, quality=95)
    print(f"[OK] Generated: {out_path}")

if __name__ == "__main__":
    fig_dir = Path("reports/project_phase_1_report/figures").resolve()
    generate_dfd_l0(fig_dir / "diagram_dfd_l0.png")
    generate_use_case(fig_dir / "diagram_use_case.png")
    generate_sequence(fig_dir / "diagram_sequence.png")
    generate_er(fig_dir / "diagram_er.png")
