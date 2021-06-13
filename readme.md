# Xiaomi Dashcam Extractor

This script will extract all files from the `Xiaomi 70mai A800 4k` Dashcam

This is a Front and Back camera.

## Usage

To extract all the video's from the dashcam to your computer use the following command.

```
./extractor.sh /path/to/dashcam/root /path/to/dashcam/library
```

### The dashcam. 

The dashcam uses the following structure.

```
/dev/70Mai/
  Event/
    Front/
      ...
    Back/
      ...
  Normal/
    Front/
      ...
    Back/
      ...
  Parking/
  Photo/
```

### Your computer

On your computer, you need the following libraries

#### The raw imported library
This library is a structured copy from the files on your dashcam SD card. The extract script will move the files to the matching recording date and the camera.

```
raw-libray/
  GT86/
    2021-06-05/
      Front/
        ...
      Back/
        ...
  GRS184/
    2021-06-05/
      Front/
        ...
      Back/
        ...
    ...
```

#### The merged library
This library contains all files that are merged together by the `concat.sh` script and mixed together in the `merge.sh` script

```
library/
  GT86/
    GT86 2021-06-05 Front.mp4
    GT86 2021-06-05 Back.mp4
    GT86 2021-06-05 Mixed.mp4
    GT86 2021-06-06 Front.mp4
    GT86 2021-06-06 Back.mp4
    GT86 2021-06-06 Mixed.mp4
    ...
  ...

```