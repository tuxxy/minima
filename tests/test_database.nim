import unittest

import ../minima/database, stew/results, os

proc checkValues(db: Database, vals: seq[seq[byte]]): bool =
    for val in vals:
        var res = db.get(val)
        if not res.isOk or res.value != val:
            return false

    return true

suite "Database Test Suite":

    var db: Database

    setup:
        var result = database.open("/tmp")
        check:
            result.isOk 

        db = result.value

    teardown:
        removeFile("/tmp/minima.db")

    test "can set and get key":
        let key = @[byte 1, 2, 3, 4]
        let value = @[byte 4, 3, 2, 1]
        
        var setResult = db.set(key, value)
        check:
            setResult.isOk

        var getResult = db.get(key)

        check:
            getResult.isOk
            getResult.value == value

    test "has returns expected value":
        let key = @[byte 1, 2, 3, 4, 5]
        check:
            not db.has(key)

        discard db.set(key, key)
        check:
            db.has(key)

    test "recover works":
        let vals = @[@[byte 1, 2, 3, 4], @[byte 1, 2, 3, 4, 5], @[byte 1, 2, 3, 4, 5, 6]]

        for val in vals:
            discard db.set(val, val)

        db.close()

        var res = database.open("/tmp")
        check:
            res.isOk

        db = res.value

        check:
            checkValues(db, vals)

    test "writes correctly to recovered file":
        let vals = @[@[byte 1, 2, 3, 4], @[byte 1, 2, 3, 4, 5], @[byte 1, 2, 3, 4, 5, 6]]

        for val in vals:
            discard db.set(val, val)

        db.close()

        var res = database.open("/tmp")
        check:
            res.isOk

        db = res.value

        check:
            checkValues(db, vals)

        let newVals = @[@[byte 1, 2, 3, 4, 5, 6, 7], @[byte 1, 2, 3, 4, 5, 6, 7, 8]]
        for val in newVals:
            discard db.set(val, val)
        
        db.close()

        res = database.open("/tmp")
        check:
            res.isOk

        db = res.value

        check:
            checkValues(db, vals)
            checkValues(db, newVals)

    test "can overwrite values":
        let key = @[byte 1, 2, 3, 4]

        discard db.set(key, key)

        check:
            db.has(key)

        discard db.set(key, @[byte 1, 2])

        var res = db.get(key)
        check:
            res.value == @[byte 1, 2]
