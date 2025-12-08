part of '../scope_provider.dart';

abstract interface class ScopeProviderFacade<W, T> {
  W get widget;
  T get model;
}
