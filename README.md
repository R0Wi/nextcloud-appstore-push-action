# Upload a new app version to Nextcloud's appstore
This Github Action automatically publishes a new app version in the Nextcloud appstore after you created a new Github release.

## Workflow
The following workflow can be automated when using this Github Action:

1. Create a new [release](https://docs.github.com/en/github/administering-a-repository/managing-releases-in-a-repository) of your app in Github.
2. Let a new Github Workflow be triggered which automates the following steps:
    - Chechout the `tag` version of your new release. 
    - Build a tarball for your app.
    - Attach the tarball to the Github Release.
    - Upload a new app version into the Nextcloud appstore referencing your attached tarball. This includes creating a signature and authenticating against Nextcloud's appstore via token (or username and password).

## Prerequisites
1. **Register** you app in the Nextcloud appstore like described [here](https://nextcloudappstore.readthedocs.io/en/latest/developer.html).
2. Paste the content of your app's **private key (`.key`) into a new [Github Secret](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)** named `APP_PRIVATE_KEY`. This key is later used for signing the new app version before uploading it to the appstore. If you want to use [code signing](https://docs.nextcloud.com/server/latest/admin_manual/issues/code_signing.html) you will need the certificate (`.crt`) of your app, too. Store it inside another secret called `APP_CERT`.

3. For **authentication** against the Nextcloud appstore you can use one of the following approaches:
    1. **Token** (recommended): create a new [Github Secret](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets) for your Nextcloud appstore account [token](https://nextcloudappstore.readthedocs.io/en/latest/restapi.html#authentication) named `APPSTORE_TOKEN`. The token can be copied by logging into https://apps.nextcloud.com an then visiting *My account -> API-Token*.
    2. **Username & password**: create two [Github Secrets](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets) `APPSTORE_USERNAME` and `APPSTORE_PASSWORD` holding your personal login information for the [Nextcloud appstore](https://apps.nextcloud.com). Make sure this user is allowed to create new app releases for you app.
4. Make sure you are able to build a tarball for your app inside of Github actions. This could be achieved by using an appropriate `Makefile`. Here are two examples:
* https://github.com/nextcloud/files_photospheres/blob/master/Makefile (without [code signing](https://docs.nextcloud.com/server/latest/admin_manual/issues/code_signing.html))
* https://github.com/nextcloud/spreed/blob/b5198c2d0d9cdc2c7c0e410867d2ec84336e23a6/Makefile (with [code signing](https://docs.nextcloud.com/server/latest/admin_manual/issues/code_signing.html))

## Usage
In general you'll have to create a new `.yml`-file in your app's repository inside of `.github/workflows` (for example `.github/workflows/build_release.yml`) to use this Github Action. The following sections list a few useful examples on how you can combine this Action with others to automate your workflow. All samples can also be found in the [`examples`](examples) directory of this repository.

### Example without [code signing](https://docs.nextcloud.com/server/latest/admin_manual/issues/code_signing.html)
The following example shows how you can use this Github Action with your Nextcloud Appstore token after a new Github Release was created:

```yaml
name: Build and publish app release

on:
  release:
      types: [published]

env:
  APP_NAME: workflow_ocr

jobs:
  build_and_publish:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
        with:
          path: ${{ env.APP_NAME }}
      - name: Run build
        run: cd ${{ env.APP_NAME }} && make appstore
      - name: Upload app tarball to release
        uses: svenstaro/upload-release-action@v2
        id: attach_to_release
        with:
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          file: ${{ env.APP_NAME }}/build/artifacts/appstore/${{ env.APP_NAME }}.tar.gz
          asset_name: ${{ env.APP_NAME }}.tar.gz 
          tag: ${{ github.ref }}
          overwrite: true
      - name: Upload app to Nextcloud appstore
        uses: R0Wi/nextcloud-appstore-push-action@v1
        env:
          app_name: ${{ env.APP_NAME }}
          appstore_token: ${{ secrets.APPSTORE_TOKEN }}
          download_url: ${{ steps.attach_to_release.outputs.browser_download_url }}
          app_private_key: ${{ secrets.APP_PRIVATE_KEY }}
          nightly: false

```

### Example including [code signing](https://docs.nextcloud.com/server/latest/admin_manual/issues/code_signing.html)
The following example show how to upload a app which makes use of [code signing](https://docs.nextcloud.com/server/latest/admin_manual/issues/code_signing.html). It assumes the following:
*  You have a `Makefile` inside of your app's root folder which makes use of the [`occ integrity:sign-app`](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#integrity-check)-command to sign the code of your app before creating the app's tarball
* The `Makefile` will use the app's private key and certificate from the root of the app folder. Please modify the paths if they do not fit your needs.

> :warning: Always make sure you never upload your app's private key inside the app's tarball by accident! Unfortunately the [`occ integrity:sign-app`](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html#integrity-check)-command currently needs the `.key` and `.crt`-files to be persisted on the local disk for signing.

```yaml
name: Build and publish app release

on:
  release:
      types: [published]

env:
  APP_NAME: workflow_ocr

jobs:
  build_and_publish:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout NC server
        uses: actions/checkout@v2
        with:
          repository: nextcloud/server
          ref: 'master'
      - name: Checkout NC submodules
        shell: bash
        run: |
          auth_header="$(git config --local --get http.https://github.com/.extraheader)"
          git submodule sync --recursive
          git -c "http.extraheader=$auth_header" -c protocol.version=2 submodule update --init --force --recursive --depth=1
      - name: Checkout app
        uses: actions/checkout@v2
        with:
          path: ${{ env.APP_NAME }}
      - name: Run build
        run: |
          cd ${{ env.APP_NAME }}
          echo "${{ secrets.APP_PRIVATE_KEY }}" > ${{ env.APP_NAME }}.key
          echo "${{ secrets.APP_CERT }}" > ${{ env.APP_NAME }}.crt
          make appstore
          rm ${{ env.APP_NAME }}.key
          rm ${{ env.APP_NAME }}.crt
      - name: Upload app tarball to release
        uses: svenstaro/upload-release-action@v2
        id: attach_to_release
        with:
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          file: ${{ env.APP_NAME }}/build/artifacts/appstore/${{ env.APP_NAME }}.tar.gz
          asset_name: ${{ env.APP_NAME }}.tar.gz 
          tag: ${{ github.ref }}
          overwrite: true
      - name: Upload app to Nextcloud appstore
        uses: R0Wi/nextcloud-appstore-push-action@v1
        env:
          app_name: ${{ env.APP_NAME }}
          appstore_token: ${{ secrets.APPSTORE_TOKEN }}
          download_url: ${{ steps.attach_to_release.outputs.browser_download_url }}
          app_private_key: ${{ secrets.APP_PRIVATE_KEY }}
          nightly: false

```

### Input variables
| Name              | Description                                                                                 | Default | Possible values | Required |
|-------------------|---------------------------------------------------------------------------------------------|---------|-----------------|----------|
| `app_name`         | The id of your Nextcloud app.                                                                | -       | `string`        | `true`   |
| `appstore_token`    | A valid access token to upload a new version of your app into Nextcloud appstore.            | -       | `string`        | `false`* |
| `appstore_username` | Username for Nextcloud appstore.                                                             | -       | `string`        | `false`* |
| `appstore_password` | Password for Nextcloud appstore.                                                          | -       | `string`        | `false`* |
| `download_url`      | The download url of your app's tarball.                                                        | -       | `string`        | `true`   |
| `app_private_key`   | The private key string of your app to sign the new release tarball (and eventually used for [code signing](https://docs.nextcloud.com/server/latest/admin_manual/issues/code_signing.html)). Usually stored in Github Secrets. | -       | `string`        | `true`   |
| `nightly`           | Controls if the app will be published as nightly into the Nextcloud appstore. This should only be set to `true` if you publish app releases via daily builds (e.g. from your `master`-branch). See [#5](https://github.com/R0Wi/nextcloud-appstore-push-action/issues/5) for more details.                | `false` | `true`, `false` | `false`  |

> *Either `appstore_token` or `appstore_username` **and** `appstore_password` must be set.

### Output variables
There are currently no output variables.