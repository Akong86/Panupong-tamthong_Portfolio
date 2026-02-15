# -*- coding: utf-8 -*-
"""
final_scraping.py — Google Maps Reviews Scraper (target-count edition)
Target: Chiang Mai P.A.O. Public Park, Chiang Mai
- Resolve exact Place
- Open All reviews
- Read TOTAL reviews count; scroll until loaded >= TOTAL
- Sort -> Newest; Language -> English (or Translate reviews)
- Extract ALL items (rating-only allowed)
Export: %USERPROFILE%/Desktop/maps_reviews/addi.csv (UTF-8-SIG)
"""

import os
import re
import time
import urllib.parse as ul
from datetime import datetime
import pandas as pd

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.keys import Keys

# ========================= CONFIG =========================
RAW_URL = "https://www.google.com/maps?hl=en&gl=US"
TARGET_NAME = "Chiang Mai P.A.O. Public Park"
TARGET_QUERY = "Chiang Mai P.A.O. Public Park, Chiang Mai, Thailand"
URL = RAW_URL if "hl=" in RAW_URL else RAW_URL + "&hl=en&gl=US"

DESKTOP = os.path.join(os.path.expanduser("~"), "Desktop")
OUTPUT_DIR = os.path.join(DESKTOP, "maps_reviews")
OUTPUT_CSV_FILE = os.path.join(OUTPUT_DIR, "addi.csv")

# ให้ Selenium Manager ใช้โฟลเดอร์โปรเจกต์ (กัน PermissionError)
os.environ["SELENIUM_MANAGER_CACHE_DIR"] = os.path.join(os.getcwd(), "selenium_cache")

THAI_PATTERN = re.compile(r"[ก-๙]")
NUM_RE = re.compile(r"([0-9][0-9,\.]*)")

# ========================= UTILS =========================
def norm(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "")).strip()

def safe_save_csv(df: pd.DataFrame, target_path: str, attempts: int = 3) -> str:
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    cand = target_path
    for i in range(attempts):
        try:
            tmp = cand + ".tmp"
            df.to_csv(tmp, index=False, encoding="utf-8-sig")
            os.replace(tmp, cand)
            print(f"✅ Saved: {cand}")
            return cand
        except Exception as e:
            print(f"⚠️ Save failed ({i+1}/{attempts}): {e}")
            base, ext = os.path.splitext(target_path)
            cand = f"{base}_{datetime.now().strftime('%Y%m%d_%H%M%S')}{ext}"
            time.sleep(0.8)
    raise RuntimeError("Could not save CSV after retries")

def click_if_present(driver, by, sel, wait=4):
    try:
        el = WebDriverWait(driver, wait).until(EC.element_to_be_clickable((by, sel)))
        driver.execute_script("arguments[0].click();", el)
        return True
    except Exception:
        return False

def get_text_or_none(el, by, sel):
    try:
        return el.find_element(by, sel).text
    except Exception:
        return None

def get_attr_or_none(el, by, sel, attr):
    try:
        return el.find_element(by, sel).get_attribute(attr)
    except Exception:
        return None

# ========================= PLACE/REVIEWS NAV =========================
def open_first_place_from_search(driver, query_text):
    url = f"https://www.google.com/maps/search/?api=1&query={ul.quote_plus(query_text)}&hl=en&gl=US"
    driver.get(url)
    time.sleep(2.2)
    try:
        first = WebDriverWait(driver, 15).until(
            EC.element_to_be_clickable((By.CSS_SELECTOR, "a[href*='/place/']"))
        )
        driver.execute_script("arguments[0].click();", first)
        time.sleep(2.0)
        return True
    except Exception:
        return False

def get_place_title(driver):
    for sel in ["h1.DUwDvf", "h1[role='heading']"]:
        try:
            t = driver.find_element(By.CSS_SELECTOR, sel).text
            if t:
                return norm(t)
        except Exception:
            pass
    return ""

def ensure_on_correct_place(driver, expected_name: str) -> bool:
    t = get_place_title(driver)
    return (t and expected_name.lower() in t.lower())

def open_place_page_by_name(driver, name: str, fallback_query: str) -> bool:
    if "/place/" in driver.current_url and ensure_on_correct_place(driver, name):
        return True
    if open_first_place_from_search(driver, name) and ensure_on_correct_place(driver, name):
        print(f"✅ Place matched: {name}")
        return True
    if open_first_place_from_search(driver, fallback_query) and ensure_on_correct_place(driver, name):
        print(f"✅ Place matched by fallback: {fallback_query}")
        return True
    print("❌ Could not resolve correct Place page"); return False

def open_full_reviews(driver):
    # พยายามเปิด All reviews ให้ได้จริง
    tries = [
        (By.CSS_SELECTOR, "button[jsaction*='pane.rating.moreReviews']"),
        (By.XPATH, "//a[contains(@href, '/reviews') or contains(., 'More reviews')]"),
        (By.CSS_SELECTOR, "button[aria-label*='Reviews']"),
        (By.XPATH, "//button[contains(., 'Reviews') or contains(., 'รีวิว')]"),
        (By.XPATH, "//div[@role='tab' and (contains(., 'Reviews') or contains(., 'รีวิว'))]"),
    ]
    for by, sel in tries:
        if click_if_present(driver, by, sel, wait=7):
            time.sleep(1.2)
            return True
    return False

def find_reviews_container(driver):
    # ตัวจริงมักเป็นกล่องเลื่อนนี้
    cands = [
    "div[tabindex='-1']", 
    "div.m6QErb.DxyBCb.kA9KIf.dS8AEf",
    "div.m6QErb.DxyBCb",
    "div[role='main']",
]
    for sel in cands:
        try:
            el = driver.find_element(By.CSS_SELECTOR, sel)
            if el:
                return el
        except Exception:
            continue
    return None

def set_sort_newest(driver):
    opened = (
        click_if_present(driver, By.CSS_SELECTOR, "button[aria-label*='Sort']", wait=4)
        or click_if_present(driver, By.XPATH, "//button[contains(., 'Sort') or contains(., 'เรียงลำดับ')]", wait=4)
        or click_if_present(driver, By.CSS_SELECTOR, "button[jsaction*='reviewChart.sort']", wait=4)
    )
    if not opened: return False
    time.sleep(0.5)
    picked = (
        click_if_present(driver, By.XPATH, "//*[@role='menuitem' and .//span[normalize-space()='Newest']]", wait=4)
        or click_if_present(driver, By.XPATH, "//span[normalize-space()='Newest']", wait=4)
    )
    if picked: time.sleep(1.0)
    return picked

def set_language_english(driver):
    opened = (
        click_if_present(driver, By.XPATH, "//*[contains(., 'All languages') and @role='button']", wait=4)
        or click_if_present(driver, By.CSS_SELECTOR, "button[aria-label*='Language']", wait=4)
        or click_if_present(driver, By.XPATH, "//button[contains(., 'Language') or contains(., 'ภาษา')]", wait=4)
    )
    if not opened: return False
    time.sleep(0.5)
    picked = (
        click_if_present(driver, By.XPATH, "//div[@role='menu']//span[normalize-space()='English']", wait=5)
        or click_if_present(driver, By.XPATH, "//li//span[normalize-space()='English']", wait=5)
    )
    if picked: time.sleep(1.0)
    return picked

def toggle_translate_reviews(driver):
    toggled = click_if_present(driver, By.XPATH, "//*[contains(., 'Translate reviews') and @role='button']", wait=3)
    if toggled: time.sleep(0.8)
    return toggled

def read_total_reviews_text(driver):
    """
    พยายามอ่านตัวเลขรวมรีวิวจากหัว/ปุ่ม เช่น "203 reviews"
    คืนเป็น int หรือ None ถ้าอ่านไม่ได้
    """
    # จุดที่มักเจอ: บริเวณหัวรีวิว/ปุ่ม reviews
    xpaths = [
        "//*[contains(., 'reviews') and not(self::script) and not(self::style)]",
        "//button[contains(@aria-label, 'reviews')]",
        "//a[contains(@href, '/reviews')]",
    ]
    texts = []
    for xp in xpaths:
        try:
            els = driver.find_elements(By.XPATH, xp)
            for e in els[:6]:
                t = norm(e.text or e.get_attribute("aria-label") or "")
                if "review" in t.lower():
                    texts.append(t)
        except Exception:
            continue
    # หาเลขมากสุดที่ดู make-sense
    best = 0
    for t in texts:
        m = NUM_RE.search(t.replace(",", ""))
        if m:
            try:
                v = int(m.group(1).replace(",", ""))
                if v > best:
                    best = v
            except Exception:
                pass
    return best if best > 0 else None

# ========================= REVIEW CARDS =========================
def find_review_cards(driver):
    sels = [
        "div.jftiEf.fontBodyMedium",
        "div.gws-localreviews__google-review",
        "div.gZ9ccf",
        "div.Dq9Eyc",
        "div.GHT2ce",
        "div[data-review-id]",
    ]
    bag = []
    for s in sels:
        try:
            bag.extend(driver.find_elements(By.CSS_SELECTOR, s))
        except Exception:
            pass
    # de-dup
    uniq, ids = [], set()
    for el in bag:
        key = getattr(el, "id", None)
        if key is None or key not in ids:
            uniq.append(el)
            if key: ids.add(key)
    return uniq

def first_text(root, queries):
    for how, sel in queries:
        try:
            t = root.find_element(By.CSS_SELECTOR if how=="css" else By.XPATH, sel).text
            t = norm(t)
            if t: return t
        except Exception:
            continue
    return None

def first_attr(root, queries):
    for how, sel, attr in queries:
        try:
            v = root.find_element(By.CSS_SELECTOR if how=="css" else By.XPATH, sel).get_attribute(attr)
            v = norm(v)
            if v: return v
        except Exception:
            continue
    return None

def per_review_translate(review_el, driver):
    xps = [
        ".//button[contains(., 'Translate')]",
        ".//button[contains(., 'See original')]",
        ".//button[contains(., 'Show original')]",
        ".//span[contains(., 'Translate')]/ancestor::button",
    ]
    for xp in xps:
        try:
            btn = review_el.find_element(By.XPATH, xp)
            driver.execute_script("arguments[0].click();", btn)
            time.sleep(0.2)
            return True
        except Exception:
            continue
    return False

# ========================= SCRAPER =========================
def scrape_all_reviews(url: str, output_csv: str):
    print("🚀 Launching Chrome (headless)")
    opts = webdriver.ChromeOptions()
    #opts.add_argument("--headless=new")
    opts.add_argument("--lang=en-US,en")
    opts.add_experimental_option("prefs", {"intl.accept_languages": "en-US,en"})
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--window-size=1400,1050")
    opts.add_argument(
        "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    )

    driver = webdriver.Chrome(service=ChromeService(), options=opts)
    wait = WebDriverWait(driver, 25)

    try:
        driver.get(url)
        print("Opening:", url)

        # ปิด cookie/consent
        for txt in ["Accept all", "Accept", "ยอมรับทั้งหมด", "ยอมรับ"]:
            if click_if_present(driver, By.XPATH, f"//button[normalize-space()='{txt}']", wait=6):
                print("Accepted cookie banner"); break

        # 1) บังคับไปหน้า Place ที่ถูกต้อง
        open_place_page_by_name(driver, TARGET_NAME, TARGET_QUERY)

        # 2) เข้า All reviews
        open_full_reviews(driver); time.sleep(1.0)

        # 3) Sort -> Newest
        set_sort_newest(driver)

        # 4) ภาษา → English หรือเปิด Translate reviews
        if not set_language_english(driver):
            toggle_translate_reviews(driver)

        # 5) หา container + อ่านจำนวนรีวิวทั้งหมด
        panel = find_reviews_container(driver)
        if panel is None: raise RuntimeError("Reviews container not found")
        print("Reviews panel located ✅")

        total = read_total_reviews_text(driver)
        if total: print(f"🔢 Total reviews (from UI): {total}")
        else: print("🔢 Total reviews unknown (will best-effort scroll)")

        # 6) สคอลล์จนสุด/จนถึง total
        last_count, no_growth = 0, 0
        no_growth_limit = 20
        max_rounds = 1000  # กันเหนียว
        for i in range(max_rounds):
            # A) เลื่อนคอนเทนเนอร์ลงบางส่วน (ค่อย ๆ)
            driver.execute_script("arguments[0].scrollBy(0, arguments[0].clientHeight*0.85);", panel)
            time.sleep(0.6)

            # B) เลื่อนเข้า element สุดท้ายให้ชัวร์
            cards = find_review_cards(driver)
            cur = len(cards)
            if cur > 0:
                try:
                    mb = c.find_element(By.XPATH, ".//button[contains(@aria-label, 'More') or contains(., 'More') or contains(., 'เพิ่มเติม')]")
                    driver.execute_script("arguments[0].click();", mb))
                    time.sleep(0.1)
                except Exception:
                    pass

            # C) ยิงปุ่ม More แถวท้าย ๆ
            try:
                more_btns = driver.find_elements(By.CSS_SELECTOR, "button.w8nwRe.kyuRq")
                for b in more_btns[-5:]:
                    driver.execute_script("arguments[0].click();", b)
                    time.sleep(0.05)
            except Exception:
                pass

            # D) ส่ง END ให้คอนเทนเนอร์หนึ่งที (เผื่อบางธีม)
            try:
                panel.send_keys(Keys.END)
                time.sleep(0.25)
            except Exception:
                pass

            # E) เช็คการโต
            cards = find_review_cards(driver)
            cur = len(cards)
            if cur > last_count:
                print(f"Loaded reviews: {cur}")
                last_count = cur
                no_growth = 0
            else:
                no_growth += 1

            # F) ครบตาม total หรือถึงจุดอิ่ม
            if total and cur >= total:
                print("Reached total review count from UI"); break
            if no_growth >= no_growth_limit:
                print("Reached end (no growth)"); break

        # 7) Extract
        cards = find_review_cards(driver)
        print(f"Extracting {len(cards)} review items...")

        rows = []
        for c in cards:
            # ขยายข้อความเต็ม
            try:
                mb = c.find_element(By.CSS_SELECTOR, "button.w8nwRe.kyuRq")
                driver.execute_script("arguments[0].click();", mb)
                time.sleep(0.03)
            except Exception:
                pass

            # ถ้าข้อความยังเห็นเป็นไทย ลองแปลรายการ
            probe = first_text(c, [("css", "span.wiI7pd"), ("css", "span.MyEned"), ("css", "div.KH5Pqf")]) or ""
            if THAI_PATTERN.search(probe):
                per_review_translate(c, driver)
                time.sleep(0.05)

            author = first_text(c, [
                ("css", "div.d4r55"),
                ("css", "button[jsaction*='pane.review.author'] span"),
                ("css", "a[aria-label][href*='contrib'] span"),
            ])
            when = first_text(c, [
                ("css", "span.rsqaWe"),
                ("css", "span.br4xNd"),
                ("css", "span.PuaHbe"),
            ])
            aria = first_attr(c, [
                ("css", "span.kvMYJc", "aria-label"),
                ("css", "span[role='img']", "aria-label"),
            ])
            rating = None
            if aria:
                m = re.search(r"(\d+(?:\.\d+)?)", aria)
                if m: rating = m.group(1)

            text = first_text(c, [
                ("css", "span.wiI7pd"),
                ("css", "span.MyEned"),
                ("css", "div.KH5Pqf"),
            ]) or ""

            rows.append({
                "author": author,
                "date": when,
                "rating": rating,
                "review_text": text
            })

        df = pd.DataFrame(rows)
        if not df.empty:
            df = df.dropna(how="all", subset=["author", "rating", "review_text"])

        saved = safe_save_csv(df, output_csv)
        print(f"✅ Done: {saved} | rows: {len(df)}")

    finally:
        driver.quit()
        print("Chrome closed")

# ========================= ENTRY =========================
if __name__ == "__main__":
    scrape_all_reviews(URL, OUTPUT_CSV_FILE)
