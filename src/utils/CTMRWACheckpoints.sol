// SPDX-License-Identifier: BSL-1.1

pragma solidity 0.8.27;

/**
 * @title Continuum Real-World Asset Checkpoints Library
 * @notice Library for tracking historical values and ownership for tokenIds
 * Optional configurations include:
 * Checkpoint (Owner-Value): uint96 alteration timestamp, address owner, uint256 value (64-byte checkpoints)
 * Checkpoint (Rate-Slot): uint96 snapshot, uint160 dividend rate, uint256 total slot balance (64-byte checkpoints)
*/
library CTMRWACheckpoints {
    error CheckpointUnorderedInsertion();

    struct CheckpointOwnerValue {
        uint96 timestamp; // 12 bytes (used as key)
        address owner;    // 20 bytes
        uint256 value;    // 32 bytes
    }

    struct TraceOwnerValue {
        CheckpointOwnerValue[] _checkpoints;
    }

    /// @notice Push a (timestamp, value, owner) checkpoint. Timestamp is the key.
    /// @dev If key is not increasing, reverts.
    function push(TraceOwnerValue storage self, uint96 key, uint256 value, address owner)
        internal
        returns (uint256 oldValue, uint256 newValue)
    {
        uint256 len = self._checkpoints.length;
        if (len > 0) {
            CheckpointOwnerValue storage last = self._checkpoints[len - 1];
            uint96 lastKey = last.timestamp;
            uint256 lastValue = last.value;
            if (lastKey > key) {
                revert CheckpointUnorderedInsertion();
            }
            if (lastKey == key) {
                last.value = value;
                last.owner = owner;
            } else {
                self._checkpoints.push(CheckpointOwnerValue({ timestamp: key, owner: owner, value: value }));
            }
            return (lastValue, value);
        } else {
            self._checkpoints.push(CheckpointOwnerValue({ timestamp: key, owner: owner, value: value }));
            return (0, value);
        }
    }

    /// @notice Returns the value in the first (oldest) checkpoint with key >= search key, or zero if none.
    /// @param key The key to search for
    /// @return value The value in the checkpoint
    /// @return owner The owner of the checkpoint
    function lowerLookup(TraceOwnerValue storage self, uint96 key) internal view returns (uint256, address) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        if (pos == len) {
            return (0, address(0));
        }
        CheckpointOwnerValue storage cp = self._checkpoints[pos];
        return (cp.value, cp.owner);
    }

    /// @notice Returns the value in the last (most recent) checkpoint with key <= search key, or zero if none.
    /// @param key The key to search for
    /// @return value The value in the checkpoint
    /// @return owner The owner of the checkpoint
    function upperLookup(TraceOwnerValue storage self, uint96 key) internal view returns (uint256, address) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        if (pos == 0) {
            return (0, address(0));
        }
        CheckpointOwnerValue storage cp = self._checkpoints[pos - 1];
        return (cp.value, cp.owner);
    }

    /// @notice Returns the value in the last (most recent) checkpoint with key <= search key, or zero if none.
    /// @dev Optimized for recent checkpoints (high keys)
    /// @param key The key to search for
    /// @return value The value in the checkpoint
    /// @return owner The owner of the checkpoint
    function upperLookupRecent(TraceOwnerValue storage self, uint96 key) internal view returns (uint256, address) {
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
        if (pos == 0) {
            return (0, address(0));
        }
        CheckpointOwnerValue storage cp = self._checkpoints[pos - 1];
        return (cp.value, cp.owner);
    }

    /// @notice Returns the value in the most recent checkpoint, or zero if none.
    /// @return value The value in the checkpoint
    /// @return owner The owner of the checkpoint
    function latest(TraceOwnerValue storage self) internal view returns (uint256, address) {
        uint256 len = self._checkpoints.length;
        if (len == 0) {
            return (0, address(0));
        }
        CheckpointOwnerValue storage cp = self._checkpoints[len - 1];
        return (cp.value, cp.owner);
    }

    /// @notice Returns whether there is a checkpoint, and if so the key, value, and owner in the most recent
    /// checkpoint.
    /// @return exists True if there is a checkpoint, false otherwise
    /// @return key The key of the checkpoint
    /// @return value The value in the checkpoint
    /// @return owner The owner of the checkpoint
    function latestCheckpoint(TraceOwnerValue storage self)
        internal
        view
        returns (bool exists, uint96 key, uint256 value, address owner)
    {
        uint256 len = self._checkpoints.length;
        if (len == 0) {
            return (false, 0, 0, address(0));
        } else {
            CheckpointOwnerValue storage cp = self._checkpoints[len - 1];
            return (true, cp.timestamp, cp.value, cp.owner);
        }
    }

    /// @notice Returns the number of checkpoints.
    /// @return The number of checkpoints
    function length(TraceOwnerValue storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /// @notice Returns checkpoint at given position.
    /// @param pos The position of the checkpoint
    /// @return key The key of the checkpoint
    /// @return value The value in the checkpoint
    /// @return owner The owner of the checkpoint
    function at(TraceOwnerValue storage self, uint32 pos) internal view returns (uint96, uint256, address) {
        CheckpointOwnerValue storage cp = self._checkpoints[pos];
        return (cp.timestamp, cp.value, cp.owner);
    }

    // --- Internal helpers ---
    /// @param self The checkpoint array
    /// @param key The key to search for
    /// @param low The lower bound of the search
    /// @param high The upper bound of the search
    /// @return The position of the checkpoint
    function _upperBinaryLookup(CheckpointOwnerValue[] storage self, uint96 key, uint256 low, uint256 high)
        private
        view
        returns (uint256)
    {
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

    /// @param self The checkpoint array
    /// @param key The key to search for
    /// @param low The lower bound of the search
    /// @param high The upper bound of the search
    /// @return The position of the checkpoint
    function _lowerBinaryLookup(CheckpointOwnerValue[] storage self, uint96 key, uint256 low, uint256 high)
        private
        view
        returns (uint256)
    {
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

    // struct CheckpointRateSlot {
    //     uint96 timestamp;   // 12 bytes (used as key)
    //     uint160 rate;       // 20 bytes
    //     uint256 balance;    // 32 bytes
    // }

    // struct TraceRateSlot {
    //     CheckpointRateSlot[] _checkpoints;
    // }

    // /// @notice Push a (timestamp, dividendRate, balance) checkpoint. Timestamp is the key.
    // /// @dev If key is not increasing, reverts.
    // function push(TraceRateSlot storage self, uint96 key, uint160 rate, uint256 balance)
    //     internal
    //     returns (uint256 oldBalance, uint160 oldRate, uint256 newBalance, uint256 newRate)
    // {
    //     uint256 len = self._checkpoints.length;
    //     if (len > 0) {
    //         CheckpointRateSlot storage last = self._checkpoints[len - 1];
    //         uint96 lastKey = last.timestamp;
    //         uint160 lastRate = last.rate;
    //         uint256 lastBalance = last.balance;
    //         if (lastKey > key) {
    //             revert CheckpointUnorderedInsertion();
    //         }
    //         if (lastKey == key) {
    //             last.rate = rate;
    //             last.balance = balance;
    //         } else {
    //             self._checkpoints.push(CheckpointRateSlot({ timestamp: key, rate: rate, balance: balance }));
    //         }
    //         return (lastBalance, lastRate, balance, rate);
    //     } else {
    //         self._checkpoints.push(CheckpointRateSlot({ timestamp: key, rate: rate, balance: balance }));
    //         return (0, 0, balance, rate);
    //     }
    // }

    // /// @notice Returns the value in the first (oldest) checkpoint with key >= search key, or zero if none.
    // /// @param key The key to search for
    // /// @return balance The balance in the checkpoint
    // /// @return rate The rate of the checkpoint
    // function lowerLookup(TraceRateSlot storage self, uint96 key) internal view returns (uint256, uint160) {
    //     uint256 len = self._checkpoints.length;
    //     uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
    //     if (pos == len) {
    //         return (0, 0);
    //     }
    //     CheckpointRateSlot storage cp = self._checkpoints[pos];
    //     return (cp.balance, cp.rate);
    // }

    // /// @notice Returns the value in the last (most recent) checkpoint with key <= search key, or zero if none.
    // /// @param key The key to search for
    // /// @return balance The balance in the checkpoint
    // /// @return rate The rate of the checkpoint
    // function upperLookup(TraceRateSlot storage self, uint96 key) internal view returns (uint256, uint160) {
    //     uint256 len = self._checkpoints.length;
    //     uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
    //     if (pos == 0) {
    //         return (0, 0);
    //     }
    //     CheckpointRateSlot storage cp = self._checkpoints[pos - 1];
    //     return (cp.balance, cp.rate);
    // }

    // /// @notice Returns the value in the last (most recent) checkpoint with key <= search key, or zero if none.
    // /// @dev Optimized for recent checkpoints (high keys)
    // /// @param key The key to search for
    // /// @return balance The balance in the checkpoint
    // /// @return rate The rate of the checkpoint
    // function upperLookupRecent(TraceRateSlot storage self, uint96 key) internal view returns (uint256, uint160) {
    //     uint256 len = self._checkpoints.length;
    //     uint256 low = 0;
    //     uint256 high = len;
    //     if (len > 5) {
    //         uint256 mid = len - _sqrt(len);
    //         if (key < self._checkpoints[mid].timestamp) {
    //             high = mid;
    //         } else {
    //             low = mid + 1;
    //         }
    //     }
    //     uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);
    //     if (pos == 0) {
    //         return (0, 0);
    //     }
    //     CheckpointRateSlot storage cp = self._checkpoints[pos - 1];
    //     return (cp.balance, cp.rate);
    // }

    // /// @notice Returns the value in the most recent checkpoint, or zero if none.
    // /// @return balance The balance in the checkpoint
    // /// @return rate The rate of the checkpoint
    // function latest(TraceRateSlot storage self) internal view returns (uint256, uint160) {
    //     uint256 len = self._checkpoints.length;
    //     if (len == 0) {
    //         return (0, 0);
    //     }
    //     CheckpointRateSlot storage cp = self._checkpoints[len - 1];
    //     return (cp.balance, cp.rate);
    // }

    // /// @notice Returns whether there is a checkpoint, and if so the key, value, and owner in the most recent
    // /// checkpoint.
    // /// @return exists True if there is a checkpoint, false otherwise
    // /// @return key The key of the checkpoint
    // /// @return balance The balance in the checkpoint
    // /// @return rate The rate of the checkpoint
    // function latestCheckpoint(TraceRateSlot storage self)
    //     internal
    //     view
    //     returns (bool exists, uint96 key, uint256 balance, uint160 rate)
    // {
    //     uint256 len = self._checkpoints.length;
    //     if (len == 0) {
    //         return (false, 0, 0, 0);
    //     } else {
    //         CheckpointRateSlot storage cp = self._checkpoints[len - 1];
    //         return (true, cp.timestamp, cp.balance, cp.rate);
    //     }
    // }

    // /// @notice Returns the number of checkpoints.
    // /// @return The number of checkpoints
    // function length(TraceRateSlot storage self) internal view returns (uint256) {
    //     return self._checkpoints.length;
    // }

    // /// @notice Returns checkpoint at given position.
    // /// @param pos The position of the checkpoint
    // /// @return key The key of the checkpoint
    // /// @return rate The rate of the checkpoint
    // /// @return balance The balance in the checkpoint
    // /// @dev return order is flipped to pack into 2 EVM slots
    // function at(TraceRateSlot storage self, uint32 pos) internal view returns (uint96, uint160, uint256) {
    //     CheckpointRateSlot storage cp = self._checkpoints[pos];
    //     return (cp.timestamp, cp.rate, cp.balance);
    // }

    // // --- Internal helpers ---
    // /// @param self The checkpoint array
    // /// @param key The key to search for
    // /// @param low The lower bound of the search
    // /// @param high The upper bound of the search
    // /// @return The position of the checkpoint
    // function _upperBinaryLookup(CheckpointRateSlot[] storage self, uint96 key, uint256 low, uint256 high)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     while (low < high) {
    //         uint256 mid = (low + high) / 2;
    //         if (self[mid].timestamp > key) {
    //             high = mid;
    //         } else {
    //             low = mid + 1;
    //         }
    //     }
    //     return high;
    // }

    // /// @param self The checkpoint array
    // /// @param key The key to search for
    // /// @param low The lower bound of the search
    // /// @param high The upper bound of the search
    // /// @return The position of the checkpoint
    // function _lowerBinaryLookup(CheckpointRateSlot[] storage self, uint96 key, uint256 low, uint256 high)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     while (low < high) {
    //         uint256 mid = (low + high) / 2;
    //         if (self[mid].timestamp < key) {
    //             low = mid + 1;
    //         } else {
    //             high = mid;
    //         }
    //     }
    //     return high;
    // }

    function _sqrt(uint256 x) private pure returns (uint256 y) {
        if (x == 0) {
            return 0;
        }
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
