const run = async () => {
    try {
        const body = {
            messages: [{ role: "user", content: [{
                "type": "text",
                "text": "Can you tell me a joke?",
            }] }],
        }

        const response = await fetch("http://127.0.0.1/chat", {
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

        console.log("Data sent successfully (streaming)");
        console.log("Response:", await response.text());
    } catch (error) {
        console.error("Error sending data (streaming):", error);
    }
};

run();
