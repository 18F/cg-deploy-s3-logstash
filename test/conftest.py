
def pytest_addoption(parser):
    parser.addoption(
        "--image",
        default="18f/logstash-s3",
        help="the docker image to test",
    )


def pytest_generate_tests(metafunc):
    if "image" in metafunc.fixturenames:
        metafunc.parametrize("image", [metafunc.config.getoption("image")])
