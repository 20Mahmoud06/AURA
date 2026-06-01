part of '../media_bloc.dart';

abstract class MediaEvent {}

class LoadMediaEvent extends MediaEvent {}

class RequestPermissionsEvent extends MediaEvent {}

class ScanDeviceEvent extends MediaEvent {}

class RefreshVideosEvent extends MediaEvent {}
