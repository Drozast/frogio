// lib/features/auth/presentation/bloc/profile/profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/update_user_profile.dart';
import '../../../domain/usecases/upload_profile_image.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UpdateUserProfile updateUserProfile;
  final UploadProfileImage uploadProfileImage;

  ProfileBloc({
    required this.updateUserProfile,
    required this.uploadProfileImage,
  }) : super(ProfileInitial()) {
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UploadProfileImageEvent>(_onUploadProfileImage);
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await updateUserProfile(
      UpdateUserProfileParams(
        userId: event.userId,
        name: event.name,
        phoneNumber: event.phoneNumber,
        address: event.address,
      ),
    );

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (user) => emit(ProfileUpdated(user: user)),
    );
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImageEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileImageUploading());

    final result = await uploadProfileImage(
      UploadProfileImageParams(
        userId: event.userId,
        imageFile: event.imageFile,
      ),
    );

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (user) => emit(ProfileImageUploaded(user: user)),
    );
  }
}