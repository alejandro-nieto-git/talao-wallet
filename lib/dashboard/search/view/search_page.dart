import 'package:altme/app/app.dart';
import 'package:altme/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_storage/secure_storage.dart' as secure_storage;

class SearchPage extends StatelessWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchCubit(
        secureStorageProvider: secure_storage.getSecureStorage,
        repository: CredentialsRepository(secure_storage.getSecureStorage),
      ),
      child: const SearchView(),
    );
  }
}

class SearchView extends StatelessWidget {
  const SearchView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: BackgroundCard(
            child: Column(
              children: [
                const Search(),
                const SizedBox(height: 15),
                if (state.status == AppStatus.loading)
                  const Expanded(child: SearchListShimmer())
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.credentials.length,
                      physics: const ScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: CredentialsListPageItem(
                            credentialModel: state.credentials[index],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
