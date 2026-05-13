import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/domain/usecases/update_profile_usecase.dart';
import 'features/auth/domain/usecases/reset_password_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

import 'features/main/data/datasources/notification_remote_data_source.dart';
import 'features/main/data/datasources/wallet_remote_data_source.dart';
import 'features/main/data/datasources/budget_remote_data_source.dart';
import 'features/main/data/repositories/wallet_repository_impl.dart';
import 'features/main/data/repositories/budget_repository_impl.dart';
import 'features/main/domain/repositories/wallet_repository.dart';
import 'features/main/domain/repositories/budget_repository.dart';
import 'features/main/domain/usecases/deposit_usecase.dart';
import 'features/main/domain/usecases/get_primary_wallet_stream_usecase.dart';
import 'features/main/domain/usecases/transfer_out_usecase.dart';
import 'features/main/domain/usecases/get_transactions_stream_usecase.dart';
import 'features/main/domain/usecases/transfer_to_user_usecase.dart';
import 'features/main/presentation/cubit/budget_cubit.dart';

final sl = GetIt.instance; // sl: Service Locator

Future<void> init() async {
  // Firebase initialization must be done before anything else. It's usually done in main()
  // but we provide instances here

  // External
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // Features - Auth
  // Cubit
  sl.registerFactory(
    () => AuthCubit(
      loginUseCase: sl(),
      registerUseCase: sl(),
      updateProfileUseCase: sl(),
      resetPasswordUseCase: sl(),
    ),
  );

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );
  sl.registerLazySingleton(() => NotificationRemoteDataSource(firestore: sl()));

  //! Features - Wallet
  sl.registerLazySingleton(() => DepositUseCase(sl()));
  sl.registerLazySingleton(() => GetPrimaryWalletStreamUseCase(sl()));
  sl.registerLazySingleton(() => TransferOutUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionsStreamUseCase(sl()));
  sl.registerLazySingleton(() => TransferToUserUseCase(sl()));

  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<BudgetRemoteDataSource>(
    () => BudgetRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(
    () => BudgetCubit(
      getPrimaryWalletStreamUseCase: sl(),
      budgetRepository: sl(),
    ),
  );

  //! Core

  //! External
}
