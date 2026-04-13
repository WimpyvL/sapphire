#!/bin/bash
# Sani — Linux Installer
# One-liner: curl -sL https://raw.githubusercontent.com/your-org/sani/main/install/install.sh | bash
set -e

TRACK="${SANI_TRACK:-${1:-web}}"
SANI_DIR="$HOME/sani"
CONDA_ENV="sani"
REPO="https://github.com/your-org/sani.git"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[Sani]${NC} $1"; }
warn()  { echo -e "${YELLOW}[Sani]${NC} $1"; }
fail()  { echo -e "${RED}[Sani]${NC} $1"; exit 1; }

install_python_deps() {
    local project_dir="$1"
    local track="$2"

    if [ "$track" = "full" ]; then
        info "Installing full dependency set..."
        pip install -r "$project_dir/requirements.txt"
        return
    fi

    info "Installing web-first dependency set..."
    pip install -r "$project_dir/install/requirements-web.txt"

    if [ "$track" = "voice" ]; then
        info "Installing optional voice add-ons..."
        pip install -r "$project_dir/install/requirements-voice.txt"
    fi
}

# ── Upgrade path ─────────────────────────────────────────────
if [ -d "$SANI_DIR/.git" ]; then
    warn "Sani is already installed at $SANI_DIR"
    read -p "Upgrade? (Y/n) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        info "Run Sani anytime: ~/sani.sh"
        exit 0
    fi

    cd "$SANI_DIR"

    # Check for local changes
    if ! git diff --quiet 2>/dev/null; then
        warn "You have local changes. Stashing them before pull..."
        git stash
    fi

    git pull || fail "git pull failed — check your network connection"

    # Activate conda in this script's shell
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/miniconda3/etc/profile.d/conda.sh"
    elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        source "$HOME/anaconda3/etc/profile.d/conda.sh"
    fi
    conda activate "$CONDA_ENV" 2>/dev/null || fail "Could not activate conda env '$CONDA_ENV'"
    install_python_deps "$SANI_DIR" "$TRACK"

    info "Sani upgraded!"
    info "Run: ~/sani.sh"
    exit 0
fi

# ── Fresh install ────────────────────────────────────────────
echo ""
echo -e "${GREEN}  ╔═══════════════════════════════════╗${NC}"
echo -e "${GREEN}  ║        Sani — Installing          ║${NC}"
echo -e "${GREEN}  ╚═══════════════════════════════════╝${NC}"
echo ""
warn "Track: $TRACK"
warn "Web is the default. Voice add-ons stay optional."
echo ""

# System deps
info "Installing system packages (may ask for sudo password)..."
sudo apt-get update -qq
sudo apt-get install -y libportaudio2 libsndfile1 git || fail "Failed to install system packages"

# Miniconda
if ! command -v conda &>/dev/null; then
    info "Installing Miniconda..."
    wget -q --show-progress https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3" || fail "Miniconda install failed"
    rm -f /tmp/miniconda.sh
    "$HOME/miniconda3/bin/conda" init bash >/dev/null 2>&1
    info "Miniconda installed. Activating for this session..."
fi

# Source conda for this session (works whether just installed or already present)
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
else
    fail "Could not find conda. Please install Miniconda manually and re-run."
fi

# Clone
info "Cloning Sani..."
git clone "$REPO" "$SANI_DIR" || fail "git clone failed"

# Conda environment
info "Creating conda environment (python 3.11)..."
conda create -n "$CONDA_ENV" python=3.11 -y || fail "Failed to create conda env"
conda activate "$CONDA_ENV"

# Python deps
info "Installing Python dependencies..."
install_python_deps "$SANI_DIR" "$TRACK" || fail "pip install failed"

# Launcher script
cat > "$HOME/sani.sh" << 'LAUNCHER'
#!/bin/bash
# Sani launcher
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
fi
conda activate sani
cd ~/sani
python main.py
LAUNCHER
chmod +x "$HOME/sani.sh"

# Done
echo ""
echo -e "${GREEN}  ╔═══════════════════════════════════╗${NC}"
echo -e "${GREEN}  ║     Sani installed successfully    ║${NC}"
echo -e "${GREEN}  ╚═══════════════════════════════════╝${NC}"
echo ""
echo "  Run anytime:  ~/sani.sh"
echo "  Web UI:       https://localhost:3004"
echo ""

read -p "Launch Sani now? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    exec "$HOME/sani.sh"
fi
