const express = require("express");
const app = express();

app.get("/:wheel-:engine-:build-:wrapping", function (req, res) {
  const wheel_id = req.params.wheel;
  const engine_id = req.params.engine;
  const build_id = req.params.build;
  const wrapping_id = req.params.wrapping;

  return res.send("Hello world");
});

app.listen(process.env.PORT || 8080); // Not sure what this point is

// Layout:

/*
  // Preuploading Steps:
  for i in range(cars)
    // STEP 1; upload all component images to IPFS
    image_link = jsaofiphe
    // STEP 2: upload all component VOX files to IPFS
    vox_link = fsoife
    // STEP 3; create and upload all component metadata to IPFS
    {"image", image_link, "vox": vox_link, "attributes": {how do we randomize these}}
    // stats? how do we determine stats? Randomizer function?

  // break

    for i:
        for j: 
            for k:
                for q:

  // STEP 4: upload all full car images to IPFS
  car_image = SFIPEF
  // STEP 5: upload all full car vox files to IPFS
  car_vox = SFIOSEF
  // STEP 6: generate and upload all full car component metadata to IPFS
  car_metadata = {"image": car_image, "vox": car_vox, }
    // MONGO example: {wheel: i, engine: j, wrapping k, build q, IPFS_METATA_LINK: car_metadata}
  // STEP 7: store this with the appropriate component id's in Mongo

  // Steps for our API
  // STEP 1: validate the id numbers are within the right range [0, max_supply)
  // STEP 2: go to mongo and put in the id's and grab that ipfs metadata link
  // STEP 3: return that IPFS metadata link to the full car

*/

/*
Uploading in directory vs. individually:

WHEEL IMAGES: in unique directory
ENGINE IMAGES: in unique directory
BUILD IMAGES: in unique directory
WRAPPING IMAGES: in unique directory

WHEEL VOX: in unique directory
ENGINE VOX: in unique directory
BUILD VOX: in unique directory
WRAPPING VOX: in unique directory

WHEEL METADATA: in unique directory
ENGINE METADATA: in unique directory
BUILD METADATA: in unique directory
WRAPPING METADATA: in unique directory

FULL CAR IMAGES: not in directory, uploaded individually
FULL CAR VOX: not in directory, uploaded individually
FULL CAR METADATA: not in directory, uploaded individually
    this is what's stored in mongo
*/
