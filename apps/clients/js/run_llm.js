const HOST = "http://127.0.0.1"

function load_image(image_path) {
    return new Promise((resolve, reject) => {
        // Read local file from image_path
        const fs = require("fs");
        fs.readFile(image_path, (err, data) => {
            if (err) {
                reject(err);
            } else {
                const fileExt = image_path.split(".").pop();
                let dataUrl = "";
                if (fileExt === "png") {
                    dataUrl = "data:image/png;base64," + data.toString("base64");
                } else if (fileExt === "jpg" || fileExt === "jpeg") {
                    dataUrl = "data:image/jpeg;base64," + data.toString("base64");
                } else {
                    throw new Error("Unsupported image format");
                }
                resolve(dataUrl);
            }
        });
    });
}

const run = async (query, image_path) => {
    try {
        const messageContent = [{
            "type": "text",
            "text": query,
        }];

        if (image_path) {
            const dataUrl = await load_image(image_path);
            // console.log("dataUrl", dataUrl);
            messageContent.push({
                "type": "image_url",
                "image_url": {
                    "url": dataUrl,
                },
            });
        }

        console.log("messageContent", JSON.stringify(messageContent));

        const messages = [{
            role: "user",
            content: messageContent,
        }];

        const body = { messages: messages }
        const response = await fetch(`${HOST}/chat`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "chat-id": "mock-chat-id",
            },
            body: JSON.stringify(body),
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        console.log("-------------------------------------------------");
        console.log("[User] " + query);
        console.log("[AI] " + (await response.text()));
        console.log("-------------------------------------------------");
    } catch (error) {
        console.error("Error sending data (streaming):", error);
    }
};

async function runAll() {
    // await run("I remembered there was a movie about a tragedy that happened in a big passenger ship, which was sinked. What was the name of the movie?");
    // await run("Oh, it's the one! Is this photo for the lead actress in the movie?", "./assets/Princess-Elsa1.png");

    await run("Search an image for Elsa from Frozen");
}

runAll();
