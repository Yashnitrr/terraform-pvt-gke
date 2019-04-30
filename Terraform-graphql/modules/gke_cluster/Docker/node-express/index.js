const app = require('express')();

app.get('/ping', (req, res) => {
    return res.status(200).json({
        success: true,
        message: 'Express application is live and running'
    });
});


app.listen(3000, () => {
    console.log("Express Application is running on port 3000")
});