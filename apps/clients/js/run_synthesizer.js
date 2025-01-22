const { Readable } = require("stream");
const fs = require("fs");

const HOST = "http://127.0.0.1"

// CURL: curl -X POST -H "Content-Type: application/octet-stream" http://127.0.0.1/speech/synthesize
const run = async () => {
    try {
        const body = JSON.stringify({ text: "Hello world" });
        const response = await fetch(`${HOST}/speech/synthesize`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body,
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        console.log("Data sent successfully (streaming)");
        const blob = await response.blob();
        console.log("Response:", blob.size);
        // // Save blob to a file
        // const buffer = await blob.arrayBuffer();
        // fs.writeFileSync("output.wav", Buffer.from(buffer));
    } catch (error) {
        console.error("Error sending data (streaming):", error);
    }
};

run();
