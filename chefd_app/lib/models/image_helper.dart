import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

// Image Helper for uploading and cropping images.
// Tutorial ref:https://www.youtube.com/watch?v=qYCsxvbPDC8&t=61s
class ImageHelper {
  ImageHelper({
    ImagePicker? imagePicker,
    ImageCropper? imageCropper,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _imageCropper = imageCropper ?? ImageCropper();

  // Our main picker and cropper objects.
  final ImagePicker _imagePicker;
  final ImageCropper _imageCropper;

  pickImageFromCamera({
    ImageSource source = ImageSource.camera,
    int imageQuality = 100,
    bool multiple = false,
  }) async {
    return await _imagePicker.pickImage(
        source: source, imageQuality: imageQuality);
  }

  pickImageFromGallery({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 100,
    bool multiple = false,
  }) async {
    return await _imagePicker.pickImage(
        source: source, imageQuality: imageQuality);
  }

  // Our crop method.
  // Auto rops to a 1 by 1 square ratio to help standardize posts.
  Future<CroppedFile?> crop({
    required XFile file,
    CropStyle cropStyle = CropStyle.rectangle,
  }) async =>
      await _imageCropper.cropImage(
          sourcePath: file.path,
          cropStyle: cropStyle,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0));
}

//////////// -- Code for Multi - photo uploading Functionality. -- ////////////
// Not needed for now.
// pickImageFromGallery({
//   ImageSource source = ImageSource.gallery,
//   int imageQuality = 100,
//   bool multiple = false,
// }) async {
//   if (multiple) {
//     return await _imagePicker.pickMultiImage(imageQuality: imageQuality);
//   }
//   final file = await _imagePicker.pickImage(
//       source: source, imageQuality: imageQuality);

//   if (file != null) return [file];
//   return [];
// }
