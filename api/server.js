const express = require("express");
const dotenv = require("dotenv");
const mongoose = require("mongoose");
const carModel = require("./models/carmodels");
const app = express();

app.use(express.json());

// username: testaccount
// password123ab
const URI =
  "mongodb+srv://testaccount:password123ab@cluster0.m1my3.mongodb.net/xlr8test?retryWrites=true&w=majority";

dotenv.config();

mongoose.connect(URI, {
  useNewUrlParser: true,
  useFindAndModify: false,
  useUnifiedTopology: true,
});

app.get("/", async (req, res) => {
  const newCar = new carModel({
    wheel: 6,
    engine: 29,
    build: 394,
    wrapping: 400,
    fullcarimage: "ipfs-full-car-image",
    fullcarvox: "ipfs-full-car-vox",
    fullcarmetadata: "ipfs-full-car-metadata",
  });

  newCar.save((err, user) => {
    if (err) {
      res.json({
        success: false,
        message: "There was a problem with saving a new car",
      });
    }
  });

  // .find() allows you to filter by certain criteria
  const cars = await carModel.find({});

  try {
    res.status(200).send(cars);
  } catch (error) {
    res.status(500).send(error);
  }
});

app.listen(3000);
