import subprocess
from flask import Flask, request, jsonify, render_template
from time import sleep
import re

app = Flask(__name__)

@app.route('/grade', methods=['POST'])
def grade():
    data = request.get_json()
    repo_url = data.get('repoUrl')

    if not repo_url:
        return jsonify({'error': 'Repository URL is required'}), 400

    if not is_valid_github_url(repo_url):
        return jsonify({'error': 'Invalid GitHub repository URL'}), 400

    try:
        username = extract_username(repo_url)
        result_file = f'/tmp/{username}_result.json'

        result = subprocess.run(['bash', './grader.sh', repo_url], capture_output=True, text=True)

        with open(result_file, 'r') as file:
            result_data = file.read()

        return jsonify({'logs': result.stdout, 'result': result_data})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def extract_username(repo_url):
    repo_url = re.sub(r'\.git$', '', repo_url)
    repo_url = re.sub(r'/tree/.*$', '', repo_url)
    repo_url = re.sub(r'/settings$', '', repo_url)
    parts = repo_url.split('/')
    if len(parts) > 4 and parts[2] == 'github.com':
        return parts[3]
    return None

def is_valid_github_url(url):
    url = re.sub(r'\.git$', '', url)
    url = re.sub(r'/tree/.*$', '', url)
    regex = re.compile(
        r'^(https?://)?(www\.)?github\.com/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+(/.*)?$'
    )
    return re.match(regex, url) is not None

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True)
