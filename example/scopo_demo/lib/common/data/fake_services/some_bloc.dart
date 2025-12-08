import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/fake_exception.dart';

sealed class SomeBlocEvent {}

final class SomeBlocLoad extends SomeBlocEvent {
  final bool fakeError;

  SomeBlocLoad({this.fakeError = false});
}

final class SomeBlocData {}

sealed class SomeBlocState extends Equatable {}

final class SomeBlocInitial extends SomeBlocState {
  @override
  List<Object?> get props => [];
}

final class SomeBlocInProgress extends SomeBlocState {
  @override
  List<Object?> get props => [];
}

final class SomeBlocSuccess extends SomeBlocState {
  final SomeBlocData data;

  SomeBlocSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

final class SomeBlocError extends SomeBlocState {
  final Object error;
  final StackTrace stackTrace;

  SomeBlocError(this.error, this.stackTrace);

  @override
  List<Object?> get props => [error, stackTrace];
}

class SomeBloc extends Bloc<SomeBlocEvent, SomeBlocState> {
  SomeBloc() : super(SomeBlocInitial()) {
    on<SomeBlocLoad>((event, emit) async {
      try {
        emit(SomeBlocInProgress());

        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (event.fakeError) {
          throw FakeException('$SomeBloc loading error');
        }
        final data = SomeBlocData();
        emit(SomeBlocSuccess(data));
      } on Object catch (e, s) {
        emit(SomeBlocError(e, s));
      }
    });
  }
}
