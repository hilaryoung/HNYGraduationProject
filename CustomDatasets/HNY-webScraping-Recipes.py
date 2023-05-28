import requests
from bs4 import BeautifulSoup
import json
import re

# Fetch the HTML content
url = "https://resepkoki.id/resep/resep-sambal-kacang/"
response = requests.get(url)
html_content = response.content

# Create a Beautiful Soup object
soup = BeautifulSoup(html_content, "html.parser")

# Create a dictionary to store the recipe details
recipe_details = {}

# Find RECIPE TITLE
div_element = soup.find("div", class_="single-title")
h1_element = div_element.find("h1")
name = h1_element.text.strip()
recipe_details["name"] = name

# Find TIME
time_outer_element = soup.find("li", class_="single-meta-cooking-time")
time_element = time_outer_element.find("span")
time_text = time_element.text.strip()
time_number = re.findall(r'\d+', time_text)[0]
recipe_details["time"] = time_number

# FIND LEVEL
level_outer_element = soup.find("li", class_="single-meta-difficulty")
level_element = level_outer_element.find("span")
level_text = level_element.text.strip().replace("Tingkat kesulitan:", "")
if level_text == " Mudah":
    new_level = "Easy"
elif level_text == " Sedang":
    new_level = "Medium"
elif level_text == " Sulit":
    new_level = "Hard"
recipe_details["level"] = new_level

# FIND SERVING
serving_outer_element = soup.find("li", class_="single-meta-serves")
serving_element = serving_outer_element.find("span")
serving_text = serving_element.text.strip()
serving_number = re.findall(r'\d+', serving_text)[0]
recipe_details["serving"] = serving_number

# FIND INGREDIENT LIST
table_element = soup.find("table", class_="ingredients-table")
row_elements = table_element.find_all("tr")
ingredients = []
for row in row_elements:
    ingredient_name_element = row.find("span", class_="ingredient-name")
    ingredient_amount_element = row.find("span", class_="ingredient-amount")
    if ingredient_name_element and ingredient_amount_element:
        ingredient_name = ingredient_name_element.text.strip()
        ingredient_amount_text = ingredient_amount_element.text.strip()
        amount_match = re.match(r"(\d+)\s*(\D+)", ingredient_amount_text)
        if amount_match:
            ingredient_amount = amount_match.group(1)
            ingredient_unit = amount_match.group(2)
        else:
            ingredient_amount = ""
            ingredient_unit = ""
        ingredient = {
            "quantity": ingredient_amount,
            "measurement": ingredient_unit,
            "name": ingredient_name
        }
        ingredients.append(ingredient)
recipe_details["ingredients"] = ingredients

# FIND STEPS LIST
table_element = soup.find("table", class_="recipe-steps-table")
row_elements = table_element.find_all("tr", class_="single-step")
recipe_steps = []
for row in row_elements:
    description_element = row.find("td", class_="single-step-description")
    description_inner_div = description_element.find("div", class_="single-step-description-i")
    step_paragraph = description_inner_div.find("p")
    if step_paragraph:
        step_description = step_paragraph.text.strip()
        recipe_steps.append(step_description)
recipe_details["steps"] = recipe_steps

# FIND WEBSITE URL FOR CREDIT
recipe_details["credLink"] = url

# FIND IMAGE URL
img_element = soup.find("img", class_="wp-post-image")
if img_element:
    image_url = img_element.get("src")
    recipe_details["coverIMG"] = image_url
else:
    print("Image not found")

# Write the recipe details to a JSON file
with open("recipes.json", "w") as file:
    json.dump(recipe_details, file, indent=4)

print("Recipe details have been written to recipes.json")
