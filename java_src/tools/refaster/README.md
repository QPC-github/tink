# Refaster templates for Tink

In this directory, we store [Refaster](https://errorprone.info/%64ocs/refaster)
templates for usage with Tink. These help users modernize the code and move to
preferred APIs. They can be used with
[Error Prone](https://errorprone.info/index), to automatically generated
patches for your codebase. The templates can be found in
`java/com/google/tink1_templates/`.

In order to use them on your project, we refer to the [Refaster
documentation](https://errorprone.info/%64ocs/refaster).

We sometimes test these templates using the script below. This script
applies the templates to the code in `java/com/google/tinkuser/*.java`
and compares the result to the code in
`java/com/google/tinkuser/*.java_expected`

NOTE: We run the following tests manually, not as part of our continuous
integration tests.


```bash
tink_version="1.8.0"
errorprone_version="2.18.0"

## STEP 0: Switch to a directory so the remainder of the script can be run
## without modifying the working directory.
code_path=$(pwd)
cd $(mktemp -d)

## STEP 1: We get the 3 jar files:
## tink-{version}-jar, error_prone_refaster-{version}.jar, and error_prone_core-{version}.jar
## (For good measure, we verify the 3 sha256sums.)
mkdir jars
pushd jars
maven_base="repo1.maven.org/maven2/com/google"

tink_jar="tink-${tink_version}.jar"
tink_sha256="92b8676c15b11a7faa15f3d1f05ed776a2897da3deba18c528ff32043339f248"

refaster_jar="error_prone_refaster-${errorprone_version}.jar"
refaster_sha256="0cde0a3db5c2f748fae4633ccd8c66a9ba9c5a0f7a380c9104b99372fd0c4959"
errorprone_jar="error_prone_core-${errorprone_version}-with-dependencies.jar"
errorprone_sha256="2b3f2d21e7754bece946cf8f7b0e2b2f805c46f58b4839eb302c3d2498a3a55e"

wget "https://${maven_base}/crypto/tink/tink/${tink_version}/${tink_jar}"
echo "${tink_sha256} ${tink_jar}" | sha256sum -c

wget "https://${maven_base}/errorprone/error_prone_refaster/${errorprone_version}/${refaster_jar}"
echo "${refaster_sha256} ${refaster_jar}" | sha256sum -c

wget "https://${maven_base}/errorprone/error_prone_core/${errorprone_version}/${errorprone_jar}"
echo "${errorprone_sha256} ${errorprone_jar}" | sha256sum -c

popd

## STEP 2: Use the current file in tink1to2 to create a "tinkrule.refaster":
cp -r "${code_path}" .

javac -cp "jars/${tink_jar}:jars/${refaster_jar}" \
  "-Xplugin:RefasterRuleCompiler --out ${PWD}/tinkrule.refaster" \
  refaster/java/com/google/tink1_templates/KeysetHandleChanges.java

## STEP 3: Use error prone to create a patch:
javac -cp "jars/${tink_jar}:jars/${errorprone_jar}" \
  -XDcompilePolicy=byfile  \
  -processorpath "jars/${errorprone_jar}" \
  "-Xplugin:ErrorProne -XepPatchChecks:refaster:${PWD}/tinkrule.refaster -XepPatchLocation:${PWD}" \
  refaster/java/com/google/tinkuser/TinkUser.java

patch refaster/java/com/google/tinkuser/TinkUser.java error-prone.patch

diff refaster/java/com/google/tinkuser/TinkUser.java \
  refaster/java/com/google/tinkuser/TinkUser.java_expected
```
