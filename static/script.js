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
	    console.log(response);
            const data = await response.json();
            if (!response.ok) {
                return data;
            }
            return data;
        })
        .then((data) => {
            result.innerHTML = "";
            if (Array.isArray(data.result)) {
                data.result.forEach((test) => {
                    const card = document.createElement("div");
                    card.className = `result-card ${test.status}`;
                    card.innerHTML = `
                        <span class="result-title">${test.title}</span>
                        <span class="result-status ${
                            test.status
                        }">${test.status.toUpperCase()}</span>
                    `;
                    result.appendChild(card);
                });
                totalScore.innerHTML = `Total Score: ${data.score}/${data.result.length}`;
            } else {
                const card = document.createElement("div");
                card.className = `result-card fail`;
                card.innerHTML = `
                        <span class="result-title">${data.error}</span>
                    `;
                result.appendChild(card);
                totalScore.innerHTML = "";
            }
            button.disabled = false;
            button.innerHTML = "Grade";
            resultSection.style.display = "block";
        });
});
