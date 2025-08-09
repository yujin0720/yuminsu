from paddleocr import PaddleOCR
from PIL import Image
import fitz  # PyMuPDF
import os

ocr = PaddleOCR(use_angle_cls=True, lang='korean')  # 한국어 지원

def extract_text_with_ocr_from_pdf(pdf_path: str) -> str:
    """PDF를 이미지로 변환 후 OCR로 텍스트 추출"""
    print(f"📌 OCR 함수 진입: {pdf_path}")
    text = ""
    try:
        doc = fitz.open(pdf_path)
        print(f"📄 PDF 페이지 수: {doc.page_count}")

        for page_num in range(doc.page_count):
            print(f"🖼️ 페이지 {page_num + 1} 변환 중...")
            page = doc.load_page(page_num)
            pix = page.get_pixmap(dpi=200)
            image_path = f"temp_page_{page_num}.png"
            pix.save(image_path)
            print(f"📸 이미지 저장 완료: {image_path}")

            # OCR 추출
            result = ocr.ocr(image_path, cls=True)
            print(f"🔍 OCR 결과: {len(result[0])}줄")

            for line in result[0]:
                line_text = line[1][0]
                text += line_text + "\n"

            os.remove(image_path)
            print(f"🧹 임시 이미지 삭제 완료: {image_path}")

        print(f"✅ OCR 전체 완료 - 총 글자 수: {len(text)}")

    except Exception as e:
        print(f"❌ OCR 실패: {e}")

    return text.strip()
