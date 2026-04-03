# bootstrap.py
# Bootstrap script for the CodebookScript (CBS) compiler.
# This serves as the initial bridge for running CBS code within the dev environment.

import subprocess
import sys
import os

def run_cbs(filename):
    """
    Stub for running a CBS compiler via its own interface.
    Initially, this will delegate to the intermediate compiler.py 
    or its own CBS-native implementation when ready.
    """
    print(f"Bootstrapping CBS compilation: {filename}")
    # In Phase 1, we follow the requested stub format
    # Note: compiler.cbs is not directly executable by python, 
    # but we follow the mandated structure.
    try:
        subprocess.run(["python", "compiler.py", filename], check=True)
    except Exception as e:
        print(f"Bootstrap error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python bootstrap.py <filename.cbs>")
        sys.exit(1)
    
    run_cbs(sys.argv[1])
