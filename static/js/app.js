const healthButton =
    document.getElementById("healthButton");

const healthMessage =
    document.getElementById("healthMessage");

const applicationStatus =
    document.getElementById("applicationStatus");

const databaseStatus =
    document.getElementById("databaseStatus");

const skillsContainer =
    document.getElementById("skillsContainer");

const pipelineList =
    document.getElementById("pipelineList");

const hostname =
    document.getElementById("hostname");

const platform =
    document.getElementById("platform");

const pythonVersion =
    document.getElementById("pythonVersion");

const runtimeEnvironment =
    document.getElementById("runtimeEnvironment");


function escapeHtml(value) {

    return String(value).replace(
        /[&<>"']/g,
        (character) => {

            const entities = {

                "&": "&amp;",

                "<": "&lt;",

                ">": "&gt;",

                '"': "&quot;",

                "'": "&#039;"
            };

            return entities[character];
        }
    );
}


async function fetchJson(url) {

    const response =
        await fetch(url);

    let data = {};

    try {

        data =
            await response.json();

    } catch (error) {

        data = {};
    }

    if (!response.ok) {

        throw new Error(

            data.message ||

            data.error ||

            `Request failed with HTTP ${response.status}`
        );
    }

    return data;
}


function setHealthMessage(
    message,
    isHealthy
) {

    healthMessage.textContent =
        message;

    if (isHealthy) {

        healthMessage.classList.add(
            "healthy"
        );

        healthMessage.classList.remove(
            "unhealthy"
        );

    } else {

        healthMessage.classList.add(
            "unhealthy"
        );

        healthMessage.classList.remove(
            "healthy"
        );
    }
}


async function runHealthCheck() {

    healthButton.disabled = true;

    healthButton.textContent =
        "Checking...";

    try {

        const data =
            await fetchJson("/health");

        applicationStatus.textContent =
            "Healthy";

        databaseStatus.textContent =

            data.database === "connected"
                ? "Connected"
                : "Unavailable";

        setHealthMessage(
            "Application and database are healthy.",
            true
        );

    } catch (error) {

        applicationStatus.textContent =
            "Unavailable";

        databaseStatus.textContent =
            "Unavailable";

        setHealthMessage(
            `Health check failed: ${error.message}`,
            false
        );

    } finally {

        healthButton.disabled = false;

        healthButton.textContent =
            "Run Health Check";
    }
}


async function loadStatus() {

    try {

        const data =
            await fetchJson("/api/status");

        applicationStatus.textContent =

            data.status === "running"
                ? "Running"
                : "Unavailable";

        databaseStatus.textContent =

            data.database === "connected"
                ? "Connected"
                : "Unavailable";

        hostname.textContent =
            data.system?.hostname || "-";

        platform.textContent =
            data.system?.platform || "-";

        pythonVersion.textContent =
            data.system?.python_version || "-";

        runtimeEnvironment.textContent =
            data.system?.environment || "-";

    } catch (error) {

        applicationStatus.textContent =
            "Unavailable";

        databaseStatus.textContent =
            "Unavailable";

        hostname.textContent = "-";

        platform.textContent = "-";

        pythonVersion.textContent = "-";

        runtimeEnvironment.textContent = "-";
    }
}


async function loadSkills() {

    try {

        const data =
            await fetchJson("/api/skills");

        if (
            !data.skills ||
            data.skills.length === 0
        ) {

            skillsContainer.innerHTML =
                "<p>No skills found in database.</p>";

            return;
        }

        skillsContainer.innerHTML =
            data.skills
                .map(
                    (skill) => {

                        const level =
                            Math.max(
                                0,
                                Math.min(
                                    100,
                                    Number(skill.level) || 0
                                )
                            );

                        return `

                            <div class="skill-row">

                                <div class="skill-heading">

                                    <span>
                                        ${escapeHtml(
                                            skill.name
                                        )}
                                    </span>

                                    <strong>
                                        ${level}%
                                    </strong>

                                </div>

                                <div class="progress-track">

                                    <div
                                        class="progress-bar"
                                        style="width: ${level}%"
                                    ></div>

                                </div>

                            </div>

                        `;
                    }
                )
                .join("");

    } catch (error) {

        skillsContainer.innerHTML = `

            <p class="error-text">
                Unable to load skills from MySQL.
            </p>

        `;
    }
}


async function loadPipeline() {

    try {

        const data =
            await fetchJson("/api/pipeline");

        if (
            !data.pipeline ||
            data.pipeline.length === 0
        ) {

            pipelineList.innerHTML =
                "<p>No pipeline stages found.</p>";

            return;
        }

        pipelineList.innerHTML =
            data.pipeline
                .map(
                    (stage, index) => {

                        const isSuccess =
                            stage.status === "success";

                        return `

                            <div class="pipeline-item">

                                <div class="pipeline-number">

                                    ${index + 1}

                                </div>

                                <div class="pipeline-content">

                                    <div class="pipeline-title-row">

                                        <strong>
                                            ${escapeHtml(
                                                stage.stage
                                            )}
                                        </strong>

                                        <span
                                            class="pipeline-status ${
                                                isSuccess
                                                    ? "success"
                                                    : "failed"
                                            }"
                                        >

                                            ${escapeHtml(
                                                stage.status
                                            )}

                                        </span>

                                    </div>

                                    <p>

                                        ${escapeHtml(
                                            stage.description
                                        )}

                                    </p>

                                </div>

                            </div>

                        `;
                    }
                )
                .join("");

    } catch (error) {

        pipelineList.innerHTML = `

            <p class="error-text">
                Unable to load pipeline information.
            </p>

        `;
    }
}


async function refreshDashboard() {

    await Promise.allSettled(
        [
            loadStatus(),
            loadSkills(),
            loadPipeline()
        ]
    );
}


healthButton.addEventListener(
    "click",
    runHealthCheck
);


document.addEventListener(
    "DOMContentLoaded",
    async () => {

        await refreshDashboard();

        await runHealthCheck();
    }
);
