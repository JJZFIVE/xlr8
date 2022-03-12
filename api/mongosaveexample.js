const express = require("express");
const dotenv = require("dotenv");
const mongoose = require("mongoose");
const carModel = require("./models/carmodels");
const app = express();

app.use(express.json());

// Mongodb testing: URI saved in the .env
// database admin username: testaccount
// password123ab

dotenv.config();
const URI = process.env.DB_URI;

mongoose.connect(URI, {
  useNewUrlParser: true,
  useFindAndModify: false,
  useUnifiedTopology: true,
});

// Main dynamic URI called by Chainlink
app.get("/:wheel/:engine/:build/:wrapping", async (req, res) => {
  //

  const newCar = new carModel({
    wheel: req.params.wheel,
    engine: req.params.engine,
    build: req.params.build,
    wrapping: req.params.wrapping,
    fullcarimage:
      "https://bafybeicwojfqzv3q43eefbazhsnrlbt32yjafr4c7rxiyf6xe2tgqrdgca.ipfs.dweb.link/fordtest/3.png",
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

  const cars = await carModel.find({});

  try {
    res.status(200).send(cars);
  } catch (error) {
    res.status(500).send(error);
  }
});

app.get("/all-cars", async (req, res) => {
  const cars = await carModel.find({});

  try {
    res.status(200).send(cars);
  } catch (error) {
    res.status(500).send(error);
  }
});

app.listen(3000);
