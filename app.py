import subprocess
from flask import Flask, request, jsonify, render_template
from time import sleep
import re

app = Flask(__name__)

@app.route('/grade', methods=['POST'])
def grade():
    sleep(2)
    data = request.get_json()
    repo_url = data.get('repoUrl')

    if not repo_url:
        return jsonify({'error': 'Repository URL is required'}), 400

    if not is_valid_github_url(repo_url):
        return jsonify({'error': 'Invalid GitHub repository URL'}), 400

    try:
        # Extract the username from the GitHub URL
        username = extract_username(repo_url)
        result_file = f'/tmp/{username}_result.json'

        # Execute the grading script (assuming 'grader.sh' is your script)
        result = subprocess.run(['bash', './grader.sh', repo_url], capture_output=True, text=True)

        # Read the result from the file
        with open(result_file, 'r') as file:
            result_data = file.read()

        return jsonify({'logs': result.stdout, 'result': result_data})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def extract_username(repo_url):
    # Extract the username from the GitHub URL
    parts = repo_url.split('/')
    return parts[-2]

def is_valid_github_url(url):
    # Regex to validate GitHub repository URL
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
