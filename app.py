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

    try:
        username = extract_username(repo_url)
        result_file = f'/tmp/{username}_result.json'

        subprocess.run(['bash', './grader.sh', repo_url])

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

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True)

