// Cloudflare Worker API URL mapped to your custom domain
const WORKER_API_URL = 'https://footshape.educhange.app'; 

// DOM Elements
const btnLogin = document.getElementById("btn-login");
const btnLoginMain = document.getElementById("btn-login-main");
const btnLogout = document.getElementById("btn-logout");
const portalSection = document.getElementById("portal-section");
const loginPrompt = document.getElementById("login-prompt");
const userNameDisplay = document.getElementById("user-name");

const fileUploader = document.getElementById("file-uploader");
const dropzone = document.getElementById("upload-dropzone");
const uploadLoader = document.getElementById("upload-loader");
const loaderSub = document.getElementById("loader-sub");
const loaderBarFill = document.getElementById("loader-bar-fill");
const fileList = document.getElementById("file-list");

let currentUser = null;

function updateUI() {
    if (currentUser) {
        if (btnLogin) btnLogin.style.display = "none";
        if (btnLogout) btnLogout.style.display = "inline-flex";
        if (loginPrompt) loginPrompt.style.display = "none";
        if (portalSection) portalSection.style.display = "block";
        if (userNameDisplay) userNameDisplay.innerText = currentUser.name;
    } else {
        if (btnLogin) btnLogin.style.display = "inline-flex";
        if (btnLogout) btnLogout.style.display = "none";
        if (loginPrompt) loginPrompt.style.display = "block";
        if (portalSection) portalSection.style.display = "none";
    }
}

// Simulated Login Logic
// Note: To implement REAL Google Auth, you would include the Google Identity Services SDK in index.html
// and initialize it with a client_id. Since Google strictly requires manual console configuration,
// we are simulating a Google login here so you can test the Cloudflare 1-click cloud storage immediately.
const login = () => {
    currentUser = {
        id: "user_" + Math.floor(Math.random() * 1000000),
        name: "Demo Google User",
        email: "demo@gmail.com"
    };
    updateUI();
};

if (btnLogin) btnLogin.addEventListener("click", login);
if (btnLoginMain) btnLoginMain.addEventListener("click", login);

if (btnLogout) {
    btnLogout.addEventListener("click", () => {
        currentUser = null;
        updateUI();
    });
}

// Upload Logic to Cloudflare Worker (R2 Storage)
if (dropzone && fileUploader) {
    dropzone.addEventListener("click", () => {
        fileUploader.click();
    });

    fileUploader.addEventListener("change", async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        if (!currentUser) {
            alert("You must be logged in to upload files.");
            return;
        }

        uploadLoader.classList.add("active");
        loaderSub.innerText = "Uploading to Cloudflare R2...";
        loaderBarFill.style.width = "50%"; 
        
        try {
            const fileName = `${currentUser.id}_${Date.now()}_${file.name}`;
            
            // PUT request directly to the Cloudflare Worker
            const response = await fetch(`${WORKER_API_URL}/upload/${encodeURIComponent(fileName)}`, {
                method: 'PUT',
                body: file
            });

            if (!response.ok) {
                throw new Error(`Worker responded with status ${response.status}`);
            }

            const data = await response.json();

            uploadLoader.classList.remove("active");
            loaderBarFill.style.width = "100%";
            loaderSub.innerText = "Complete";

            const li = document.createElement("li");
            li.style.padding = "10px 0";
            li.style.borderBottom = "1px solid rgba(255,255,255,0.1)";
            li.innerHTML = `<a href="${data.url}" target="_blank" style="color: #00F2FE; text-decoration: none;"><i class="fa-solid fa-file"></i> ${file.name}</a>`;
            
            if (fileList.innerText.includes("No files uploaded")) {
                fileList.innerHTML = "";
            }
            fileList.appendChild(li);

        } catch (error) {
            console.error("Upload failed", error);
            uploadLoader.classList.remove("active");
            alert("Upload failed. Make sure your Cloudflare worker is running! In your terminal, run 'cd worker && npx wrangler dev' to start it locally.");
        }
    });
}

updateUI();
