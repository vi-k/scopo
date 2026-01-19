import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../utils/app_environment.dart';
import '../../domain/fake_exception.dart';

sealed class FakeBlocEvent {}

final class FakeBlocLoad extends FakeBlocEvent {
  FakeBlocLoad();
}

final class FakeBlocData {}

sealed class FakeBlocState extends Equatable {}

final class FakeBlocInitial extends FakeBlocState {
  @override
  List<Object?> get props => [];
}

final class FakeBlocInProgress extends FakeBlocState {
  @override
  List<Object?> get props => [];
}

final class FakeBlocSuccess extends FakeBlocState {
  final FakeBlocData data;

  FakeBlocSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

final class FakeBlocError extends FakeBlocState {
  final Object error;
  final StackTrace stackTrace;

  FakeBlocError(this.error, this.stackTrace);

  @override
  List<Object?> get props => [error, stackTrace];
}

class FakeBloc extends Bloc<FakeBlocEvent, FakeBlocState> {
  FakeBloc() : super(FakeBlocInitial()) {
    on<FakeBlocLoad>((event, emit) async {
      try {
        emit(FakeBlocInProgress());

        await Future<void>.delayed(AppEnvironment.defaultInitPause);
        if (AppEnvironment.errorOnFakeBlocLoading) {
          throw FakeException('$FakeBloc loading error');
        }

        final data = FakeBlocData();
        emit(FakeBlocSuccess(data));
      } on Object catch (e, s) {
        emit(FakeBlocError(e, s));
      }
    });
  }
}
