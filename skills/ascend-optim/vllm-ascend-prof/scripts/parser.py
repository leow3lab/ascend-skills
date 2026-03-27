import argparse
from torch_npu.profiler.profiler import analyse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", "-p", required=True)
    args = parser.parse_args()

    analyse(profiler_path=args.path)
