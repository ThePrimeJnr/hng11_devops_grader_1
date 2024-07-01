import subprocess
from flask import Flask, request, jsonify, render_template
import re

app = Flask(__name__)

@app.route('/grade', methods=['POST'])
def grade():
    data = request.get_json()
    repo_url = data.get('repoUrl')

    if not repo_url:
        return jsonify({'score': 0, 'error': 'Repository URL is required'}), 200

    cleaned_url = clean_github_url(repo_url)
    if not cleaned_url:
        return jsonify({'score': 0, 'error': 'Invalid GitHub repository URL'}), 200

    try:
        username = extract_username(cleaned_url)
        result_file = f'/tmp/{username}_result.json'

        subprocess.run(['bash', './grader.sh', cleaned_url])

        with open(result_file, 'r') as file:
            result_data = file.read()

        return result_data
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def extract_username(repo_url):
    parts = repo_url.split('/')
    if len(parts) > 3:
        return parts[3]
    return None

def clean_github_url(url):
    regex = re.compile(r'^(https?://)?(www\.)?github\.com/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+')
    match = re.search(regex, url)
    if match:
        return match.group(0)
    return None

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True)

