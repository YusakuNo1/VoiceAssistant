const { Readable } = require("stream");
const fs = require("fs");

const HOST = "http://127.0.0.1"

const run = async () => {
    let index = 0;

    function createCustomStream() {
        const stream = new Readable({
            read() {
                setTimeout(() => {
                    console.log("Reading data...", index);
    
                    // const data = { index, content: `Data chunk ${index}` };
                    // const chunk = JSON.stringify(data);
                    // this.push(chunk);

                    // this.push(`Data: ${index}`);

                    switch (index) {
                        case 0: this.push(String.fromCharCode(25)); break;
                        case 1: this.push(String.fromCharCode(26)); break;
                        case 2: this.push(String.fromCharCode(27)); break;
                    }

                    index++;
        
                    // End the stream after a certain number of chunks (optional)
                    if (index > 2) {
                        this.push(null); // Signal end of stream
                    }    
                }, 500);
            },
        });
        return stream;
    }

    function createFileStream() {
        // const stream = fs.createReadStream("../audio/speech_tell_me_a_joke.m4a");
        // const stream = fs.createReadStream("../audio/whatstheweatherlike.wav");
        // const stream = fs.createReadStream("../audio/pronunciation_assessment_fall.wav");
        const stream = fs.createReadStream("../audio/zhcn_short_dummy_sample.wav");
        return stream;
    }

    // const stream = createCustomStream();
    const stream = createFileStream();

    try {
        const response = await fetch(`${HOST}/speech/recognize`, {
            method: "POST",
            headers: {
                "Content-Type": "application/octet-stream",
            },
            body: stream,
            duplex: "half", // Add this line
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
