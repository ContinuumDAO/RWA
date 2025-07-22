// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title TokenCheckpoints
/// @notice Library for tracking historical values and ownership for tokenIds, using 64-byte checkpoints (timestamp, address, uint256 value)
library TokenCheckpoints {
    error CheckpointUnorderedInsertion();

    struct CheckpointFull {
        uint96 timestamp;   // 12 bytes (used as key)
        address owner;      // 20 bytes
        uint256 value;      // 32 bytes
    }

    struct Trace {
        CheckpointFull[] _checkpoints;
    }

    /// @notice Push a (timestamp, value, owner) checkpoint. Timestamp is the key.
    /// @dev If key is not increasing, reverts.
    function push(Trace storage self, uint96 key, uint256 value, address owner) internal returns (uint256 oldValue, uint256 newValue) {
        uint256 len = self._checkpoints.length;
        if (len > 0) {
            CheckpointFull storage last = self._checkpoints[len - 1];
            uint96 lastKey = last.timestamp;
            uint256 lastValue = last.value;
            if (lastKey > key) revert CheckpointUnorderedInsertion();
            if (lastKey == key) {
                last.value = value;
                last.owner = owner;
            } else {
                self._checkpoints.push(CheckpointFull({timestamp: key, owner: owner, value: value}));
            }
            return (lastValue, value);
        } else {
            self._checkpoints.push(CheckpointFull({timestamp: key, owner: owner, value: value}));
            return (0, value);
        }
    }

    /// @notice Returns the value in the first (oldest) checkpoint with key >= search key, or zero if none.
    function lowerLookup(Trace storage self, uint96 key) internal view returns (uint256, address) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        if (pos == len) return (0, address(0));
        CheckpointFull storage cp = self._checkpoints[pos];
        return (cp.value, cp.owner);
    }

    /// @notice Returns the value in the last (most recent) checkpoint with key <= search key, or zero if none.
    function upperLookup(Trace storage self, uint96 key) internal view returns (uint256, address) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        if (pos == 0) return (0, address(0));
        CheckpointFull storage cp = self._checkpoints[pos - 1];
        return (cp.value, cp.owner);
    }

    /// @notice Returns the value in the last (most recent) checkpoint with key <= search key, or zero if none.
    /// @dev Optimized for recent checkpoints (high keys)
    function upperLookupRecent(Trace storage self, uint96 key) internal view returns (uint256, address) {
        uint256 len = self._checkpoints.length;
        uint256 low = 0;
        uint256 high = len;
        if (len > 5) {
            uint256 mid = len - _sqrt(len);
            if (key < self._checkpoints[mid].timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);
        if (pos == 0) return (0, address(0));
        CheckpointFull storage cp = self._checkpoints[pos - 1];
        return (cp.value, cp.owner);
    }

    /// @notice Returns the value in the most recent checkpoint, or zero if none.
    function latest(Trace storage self) internal view returns (uint256, address) {
        uint256 len = self._checkpoints.length;
        if (len == 0) return (0, address(0));
        CheckpointFull storage cp = self._checkpoints[len - 1];
        return (cp.value, cp.owner);
    }

    /// @notice Returns whether there is a checkpoint, and if so the key, value, and owner in the most recent checkpoint.
    function latestCheckpoint(Trace storage self) internal view returns (bool exists, uint96 key, uint256 value, address owner) {
        uint256 len = self._checkpoints.length;
        if (len == 0) {
            return (false, 0, 0, address(0));
        } else {
            CheckpointFull storage cp = self._checkpoints[len - 1];
            return (true, cp.timestamp, cp.value, cp.owner);
        }
    }

    /// @notice Returns the number of checkpoints.
    function length(Trace storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /// @notice Returns checkpoint at given position.
    function at(Trace storage self, uint32 pos) internal view returns (uint96, uint256, address) {
        CheckpointFull storage cp = self._checkpoints[pos];
        return (cp.timestamp, cp.value, cp.owner);
    }

    // --- Internal helpers ---
    function _upperBinaryLookup(CheckpointFull[] storage self, uint96 key, uint256 low, uint256 high) private view returns (uint256) {
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (self[mid].timestamp > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    function _lowerBinaryLookup(CheckpointFull[] storage self, uint96 key, uint256 low, uint256 high) private view returns (uint256) {
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (self[mid].timestamp < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    function _sqrt(uint256 x) private pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
} 