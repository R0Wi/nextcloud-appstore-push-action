# Upload a new app version to Nextcloud's appstore
This Github Action automatically publishes a new app version in the Nextcloud appstore after you created a new Github release.

## Workflow
The following workflow will be automated by this Action:

1. Develop your app.
2. Create a new [release](https://docs.github.com/en/github/administering-a-repository/managing-releases-in-a-repository).
3. Let a new Github Workflow be triggered which automates the following steps:
    - Chechout the `tag` version of your new release. 
    - Build a tarball for your app.
    - Attach the tarball to the Github Release.
    - Upload a new app version into the Nextcloud appstore referencing your attached tarball. This includes creating a signature and authenticating against Nextcloud's appstore via token.

## Prerequisites
1. **Register** you app in the Nextcloud appstore like described [here](https://nextcloudappstore.readthedocs.io/en/latest/developer.html).
2. Paste the content of your app's **private key into a new [Github Secret](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)** of your app's repository (e.g. with the key `APP_PRIVATE_KEY`). This key is later used for signing the new app version before uploading it to the appstore.
3. Create a new [Github Secret](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets) for your **Nextcloud appstore account [token](https://nextcloudappstore.readthedocs.io/en/latest/restapi.html#authentication)** (e.g. with the key `APPSTORE_TOKEN`). The token can be copied by logging into https://apps.nextcloud.com an then visiting *My account -> API-Token*.
4. Make sure you are able to build a tarball for your app inside of Github actions. This could be achieved by using an appropriate [`Makefile`](https://github.com/nextcloud/files_photospheres/blob/master/Makefile).

## Usage
### Example
The following example shows how you can use this Github Action after a new Github Release was created:

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
          nightly: ${{ github.event.release.prerelease }}

```

> You'll have to store this file inside of your app's repository. For example under `.github/workflows/build_release.yml`.

### Input variables
* `app_name`: The id of your Nextcloud app *(required)*
* `appstore_token`: A valid access token to upload a new version of your app into Nextcloud appstore *(required)*
* `download_url`: The download url of you app tarball *(required)*
* `app_private_key`: The private key string of you app to sign the new release. Usually stored in Github Secrets *(required)*
* `nightly`: Controls if the app will be published as nightly into the Nextcloud appstore *(optional, default = `false`)*
### Output variables
There are currently no output variables.