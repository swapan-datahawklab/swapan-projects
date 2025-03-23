chmod +x create_project_structure.sh &&\
chmod +x create_test_structure.sh &&\
chmod +x create_test.sh &&\
chmod +x create_test.sh &&\

bash ./create_test.sh &&\
bash ./create_test_structure.sh &&\
bash ./create_project_structure.sh

oc login --token=sha256~${TOKEN} --server=https://api.sandbox-m2.ll9k.p1.openshiftapps.com:6443
curl -H "Authorization: Bearer sha256~${TOKEN}" "https://api.sandbox-m2.ll9k.p1.openshiftapps.com:6443/apis/user.openshift.io/v1/users/~"

export TEST_DIR="src/test/java/com/company/automation" &&\
mkdir -p ${TEST_DIR}/service &&\
mkdir -p ${TEST_DIR}/controller &&\
mkdir -p ${TEST_DIR}/advice &&\
touch ${TEST_DIR}/advice/GlobalExceptionHandlerTest.java &&\
touch ${TEST_DIR}/controller/ArtifactoryControllerTest.java &&\
touch ${TEST_DIR}/service/ArtifactoryServiceTest.java