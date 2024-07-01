document.getElementById("gradingForm").addEventListener("submit", function (e) {
    e.preventDefault();
    const repoUrl = document.getElementById("repoUrl").value;
    const button = document.getElementById("gradeButton");
    const resultSection = document.getElementById("resultSection");
    const result = document.getElementById("result");
    const totalScore = document.getElementById("totalScore");

    button.disabled = true;
    button.innerHTML = '<div class="button-spinner"></div>';
    resultSection.style.display = "none";

    fetch("/grade", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ repoUrl }),
    })
        .then(async (response) => {
            const data = await response.json();
            if (!response.ok) {
                return data.error;
            }
            return data.result;
        })
        .then((data) => {
            result.innerHTML = "";
            let score = 0;
            try {
                data = JSON.parse(data);
            } catch (error) {}
            if (Array.isArray(data)) {
                data.forEach((test) => {
                    const card = document.createElement("div");
                    card.className = `result-card ${test.status}`;
                    card.innerHTML = `
                        <span class="result-title">${test.title}</span>
                        <span class="result-status ${
                            test.status
                        }">${test.status.toUpperCase()}</span>
                    `;
                    result.appendChild(card);
                    if (test.status === "pass") {
                        score += 1;
                    }
                });
                totalScore.innerHTML = `Total Score: ${score}/${data.length}`;
            } else {
                const card = document.createElement("div");
                card.className = `result-card fail`;
                card.innerHTML = `
                        <span class="result-title">${data}</span>
                    `;
                result.appendChild(card);
                totalScore.innerHTML = "";
            }
            button.disabled = false;
            button.innerHTML = "Grade";
            resultSection.style.display = "block";
        });
});
