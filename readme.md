# Xiaomi Dashcam Extractor

This script will extract all files from the `Xiaomi 70mai A800 4k` Dashcam

This is a Front and Back camera.

## Usage

There are two storage systems

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

If you have multiple cars or want to structure your library, it's reccomended to create seperate folders for each car.

```
dashcam/
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