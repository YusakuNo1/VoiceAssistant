from PIL import Image
from io import BytesIO
import base64
import requests

def convert_data_url(image_url, max_size=512):
  """
  Downloads an image from the given URL and resizes it 
  so that the larger dimension is at most `max_size`.

  Args:
    image_url: The URL of the image to download.
    max_size: The maximum size for the larger dimension.

  Returns:
    A PIL Image object of the resized image.
  """
  try:
    response = requests.get(image_url)
    if response.status_code != 200:
      return None

    img = Image.open(BytesIO(response.content))

    width, height = img.size
    if width > height:
      new_width = max_size
      new_height = int(height * max_size / width)
    else:
      new_height = max_size
      new_width = int(width * max_size / height)

    resized_img = img.resize((new_width, new_height), Image.LANCZOS)  # Use LANCZOS for better quality

    image_format = "jpeg"
    buffered = BytesIO()
    resized_img.save(buffered, format=image_format)
    img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
    return f"data:image/{image_format};base64,{img_str}"

  except (requests.exceptions.RequestException, OSError) as e:
    print(f"Error downloading or processing image: {e}")
    return None
