function o3(e, t) {
  for (var n = 0; n < t.length; n++) {
    const r = t[n];
    if (typeof r != "string" && !Array.isArray(r)) {
      for (const l in r)
        if (l !== "default" && !(l in e)) {
          const i = Object.getOwnPropertyDescriptor(r, l);
          i &&
            Object.defineProperty(
              e,
              l,
              i.get ? i : { enumerable: !0, get: () => r[l] }
            );
        }
    }
  }
  return Object.freeze(
    Object.defineProperty(e, Symbol.toStringTag, { value: "Module" })
  );
}
(function () {
  const t = document.createElement("link").relList;
  if (t && t.supports && t.supports("modulepreload")) return;
  for (const l of document.querySelectorAll('link[rel="modulepreload"]')) r(l);
  new MutationObserver((l) => {
    for (const i of l)
      if (i.type === "childList")
        for (const o of i.addedNodes)
          o.tagName === "LINK" && o.rel === "modulepreload" && r(o);
  }).observe(document, { childList: !0, subtree: !0 });
  function n(l) {
    const i = {};
    return (
      l.integrity && (i.integrity = l.integrity),
      l.referrerPolicy && (i.referrerPolicy = l.referrerPolicy),
      l.crossOrigin === "use-credentials"
        ? (i.credentials = "include")
        : l.crossOrigin === "anonymous"
        ? (i.credentials = "omit")
        : (i.credentials = "same-origin"),
      i
    );
  }
  function r(l) {
    if (l.ep) return;
    l.ep = !0;
    const i = n(l);
    fetch(l.href, i);
  }
})();
function ka(e) {
  return e && e.__esModule && Object.prototype.hasOwnProperty.call(e, "default")
    ? e.default
    : e;
}
var La = { exports: {} },
  fl = {},
  _a = { exports: {} },
  R = {};
/**
 * @license React
 * react.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var ir = Symbol.for("react.element"),
  s3 = Symbol.for("react.portal"),
  a3 = Symbol.for("react.fragment"),
  u3 = Symbol.for("react.strict_mode"),
  c3 = Symbol.for("react.profiler"),
  f3 = Symbol.for("react.provider"),
  d3 = Symbol.for("react.context"),
  p3 = Symbol.for("react.forward_ref"),
  m3 = Symbol.for("react.suspense"),
  h3 = Symbol.for("react.memo"),
  v3 = Symbol.for("react.lazy"),
  is = Symbol.iterator;
function g3(e) {
  return e === null || typeof e != "object"
    ? null
    : ((e = (is && e[is]) || e["@@iterator"]),
      typeof e == "function" ? e : null);
}
var Na = {
    isMounted: function () {
      return !1;
    },
    enqueueForceUpdate: function () {},
    enqueueReplaceState: function () {},
    enqueueSetState: function () {},
  },
  Pa = Object.assign,
  za = {};
function fn(e, t, n) {
  (this.props = e),
    (this.context = t),
    (this.refs = za),
    (this.updater = n || Na);
}
fn.prototype.isReactComponent = {};
fn.prototype.setState = function (e, t) {
  if (typeof e != "object" && typeof e != "function" && e != null)
    throw Error(
      "setState(...): takes an object of state variables to update or a function which returns an object of state variables."
    );
  this.updater.enqueueSetState(this, e, t, "setState");
};
fn.prototype.forceUpdate = function (e) {
  this.updater.enqueueForceUpdate(this, e, "forceUpdate");
};
function Ma() {}
Ma.prototype = fn.prototype;
function ro(e, t, n) {
  (this.props = e),
    (this.context = t),
    (this.refs = za),
    (this.updater = n || Na);
}
var lo = (ro.prototype = new Ma());
lo.constructor = ro;
Pa(lo, fn.prototype);
lo.isPureReactComponent = !0;
var os = Array.isArray,
  Ta = Object.prototype.hasOwnProperty,
  io = { current: null },
  Ra = { key: !0, ref: !0, __self: !0, __source: !0 };
function Da(e, t, n) {
  var r,
    l = {},
    i = null,
    o = null;
  if (t != null)
    for (r in (t.ref !== void 0 && (o = t.ref),
    t.key !== void 0 && (i = "" + t.key),
    t))
      Ta.call(t, r) && !Ra.hasOwnProperty(r) && (l[r] = t[r]);
  var a = arguments.length - 2;
  if (a === 1) l.children = n;
  else if (1 < a) {
    for (var u = Array(a), f = 0; f < a; f++) u[f] = arguments[f + 2];
    l.children = u;
  }
  if (e && e.defaultProps)
    for (r in ((a = e.defaultProps), a)) l[r] === void 0 && (l[r] = a[r]);
  return {
    $$typeof: ir,
    type: e,
    key: i,
    ref: o,
    props: l,
    _owner: io.current,
  };
}
function x3(e, t) {
  return {
    $$typeof: ir,
    type: e.type,
    key: t,
    ref: e.ref,
    props: e.props,
    _owner: e._owner,
  };
}
function oo(e) {
  return typeof e == "object" && e !== null && e.$$typeof === ir;
}
function y3(e) {
  var t = { "=": "=0", ":": "=2" };
  return (
    "$" +
    e.replace(/[=:]/g, function (n) {
      return t[n];
    })
  );
}
var ss = /\/+/g;
function Dl(e, t) {
  return typeof e == "object" && e !== null && e.key != null
    ? y3("" + e.key)
    : t.toString(36);
}
function Pr(e, t, n, r, l) {
  var i = typeof e;
  (i === "undefined" || i === "boolean") && (e = null);
  var o = !1;
  if (e === null) o = !0;
  else
    switch (i) {
      case "string":
      case "number":
        o = !0;
        break;
      case "object":
        switch (e.$$typeof) {
          case ir:
          case s3:
            o = !0;
        }
    }
  if (o)
    return (
      (o = e),
      (l = l(o)),
      (e = r === "" ? "." + Dl(o, 0) : r),
      os(l)
        ? ((n = ""),
          e != null && (n = e.replace(ss, "$&/") + "/"),
          Pr(l, t, n, "", function (f) {
            return f;
          }))
        : l != null &&
          (oo(l) &&
            (l = x3(
              l,
              n +
                (!l.key || (o && o.key === l.key)
                  ? ""
                  : ("" + l.key).replace(ss, "$&/") + "/") +
                e
            )),
          t.push(l)),
      1
    );
  if (((o = 0), (r = r === "" ? "." : r + ":"), os(e)))
    for (var a = 0; a < e.length; a++) {
      i = e[a];
      var u = r + Dl(i, a);
      o += Pr(i, t, n, u, l);
    }
  else if (((u = g3(e)), typeof u == "function"))
    for (e = u.call(e), a = 0; !(i = e.next()).done; )
      (i = i.value), (u = r + Dl(i, a++)), (o += Pr(i, t, n, u, l));
  else if (i === "object")
    throw (
      ((t = String(e)),
      Error(
        "Objects are not valid as a React child (found: " +
          (t === "[object Object]"
            ? "object with keys {" + Object.keys(e).join(", ") + "}"
            : t) +
          "). If you meant to render a collection of children, use an array instead."
      ))
    );
  return o;
}
function dr(e, t, n) {
  if (e == null) return e;
  var r = [],
    l = 0;
  return (
    Pr(e, r, "", "", function (i) {
      return t.call(n, i, l++);
    }),
    r
  );
}
function C3(e) {
  if (e._status === -1) {
    var t = e._result;
    (t = t()),
      t.then(
        function (n) {
          (e._status === 0 || e._status === -1) &&
            ((e._status = 1), (e._result = n));
        },
        function (n) {
          (e._status === 0 || e._status === -1) &&
            ((e._status = 2), (e._result = n));
        }
      ),
      e._status === -1 && ((e._status = 0), (e._result = t));
  }
  if (e._status === 1) return e._result.default;
  throw e._result;
}
var ce = { current: null },
  zr = { transition: null },
  w3 = {
    ReactCurrentDispatcher: ce,
    ReactCurrentBatchConfig: zr,
    ReactCurrentOwner: io,
  };
R.Children = {
  map: dr,
  forEach: function (e, t, n) {
    dr(
      e,
      function () {
        t.apply(this, arguments);
      },
      n
    );
  },
  count: function (e) {
    var t = 0;
    return (
      dr(e, function () {
        t++;
      }),
      t
    );
  },
  toArray: function (e) {
    return (
      dr(e, function (t) {
        return t;
      }) || []
    );
  },
  only: function (e) {
    if (!oo(e))
      throw Error(
        "React.Children.only expected to receive a single React element child."
      );
    return e;
  },
};
R.Component = fn;
R.Fragment = a3;
R.Profiler = c3;
R.PureComponent = ro;
R.StrictMode = u3;
R.Suspense = m3;
R.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = w3;
R.cloneElement = function (e, t, n) {
  if (e == null)
    throw Error(
      "React.cloneElement(...): The argument must be a React element, but you passed " +
        e +
        "."
    );
  var r = Pa({}, e.props),
    l = e.key,
    i = e.ref,
    o = e._owner;
  if (t != null) {
    if (
      (t.ref !== void 0 && ((i = t.ref), (o = io.current)),
      t.key !== void 0 && (l = "" + t.key),
      e.type && e.type.defaultProps)
    )
      var a = e.type.defaultProps;
    for (u in t)
      Ta.call(t, u) &&
        !Ra.hasOwnProperty(u) &&
        (r[u] = t[u] === void 0 && a !== void 0 ? a[u] : t[u]);
  }
  var u = arguments.length - 2;
  if (u === 1) r.children = n;
  else if (1 < u) {
    a = Array(u);
    for (var f = 0; f < u; f++) a[f] = arguments[f + 2];
    r.children = a;
  }
  return { $$typeof: ir, type: e.type, key: l, ref: i, props: r, _owner: o };
};
R.createContext = function (e) {
  return (
    (e = {
      $$typeof: d3,
      _currentValue: e,
      _currentValue2: e,
      _threadCount: 0,
      Provider: null,
      Consumer: null,
      _defaultValue: null,
      _globalName: null,
    }),
    (e.Provider = { $$typeof: f3, _context: e }),
    (e.Consumer = e)
  );
};
R.createElement = Da;
R.createFactory = function (e) {
  var t = Da.bind(null, e);
  return (t.type = e), t;
};
R.createRef = function () {
  return { current: null };
};
R.forwardRef = function (e) {
  return { $$typeof: p3, render: e };
};
R.isValidElement = oo;
R.lazy = function (e) {
  return { $$typeof: v3, _payload: { _status: -1, _result: e }, _init: C3 };
};
R.memo = function (e, t) {
  return { $$typeof: h3, type: e, compare: t === void 0 ? null : t };
};
R.startTransition = function (e) {
  var t = zr.transition;
  zr.transition = {};
  try {
    e();
  } finally {
    zr.transition = t;
  }
};
R.unstable_act = function () {
  throw Error("act(...) is not supported in production builds of React.");
};
R.useCallback = function (e, t) {
  return ce.current.useCallback(e, t);
};
R.useContext = function (e) {
  return ce.current.useContext(e);
};
R.useDebugValue = function () {};
R.useDeferredValue = function (e) {
  return ce.current.useDeferredValue(e);
};
R.useEffect = function (e, t) {
  return ce.current.useEffect(e, t);
};
R.useId = function () {
  return ce.current.useId();
};
R.useImperativeHandle = function (e, t, n) {
  return ce.current.useImperativeHandle(e, t, n);
};
R.useInsertionEffect = function (e, t) {
  return ce.current.useInsertionEffect(e, t);
};
R.useLayoutEffect = function (e, t) {
  return ce.current.useLayoutEffect(e, t);
};
R.useMemo = function (e, t) {
  return ce.current.useMemo(e, t);
};
R.useReducer = function (e, t, n) {
  return ce.current.useReducer(e, t, n);
};
R.useRef = function (e) {
  return ce.current.useRef(e);
};
R.useState = function (e) {
  return ce.current.useState(e);
};
R.useSyncExternalStore = function (e, t, n) {
  return ce.current.useSyncExternalStore(e, t, n);
};
R.useTransition = function () {
  return ce.current.useTransition();
};
R.version = "18.2.0";
_a.exports = R;
var S = _a.exports;
const so = ka(S),
  S3 = o3({ __proto__: null, default: so }, [S]);
/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var E3 = S,
  j3 = Symbol.for("react.element"),
  k3 = Symbol.for("react.fragment"),
  L3 = Object.prototype.hasOwnProperty,
  _3 = E3.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner,
  N3 = { key: !0, ref: !0, __self: !0, __source: !0 };
function Oa(e, t, n) {
  var r,
    l = {},
    i = null,
    o = null;
  n !== void 0 && (i = "" + n),
    t.key !== void 0 && (i = "" + t.key),
    t.ref !== void 0 && (o = t.ref);
  for (r in t) L3.call(t, r) && !N3.hasOwnProperty(r) && (l[r] = t[r]);
  if (e && e.defaultProps)
    for (r in ((t = e.defaultProps), t)) l[r] === void 0 && (l[r] = t[r]);
  return {
    $$typeof: j3,
    type: e,
    key: i,
    ref: o,
    props: l,
    _owner: _3.current,
  };
}
fl.Fragment = k3;
fl.jsx = Oa;
fl.jsxs = Oa;
La.exports = fl;
var s = La.exports,
  ai = {},
  Ua = { exports: {} },
  we = {},
  Fa = { exports: {} },
  Ba = {};
/**
 * @license React
 * scheduler.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ (function (e) {
  function t(L, M) {
    var T = L.length;
    L.push(M);
    e: for (; 0 < T; ) {
      var W = (T - 1) >>> 1,
        q = L[W];
      if (0 < l(q, M)) (L[W] = M), (L[T] = q), (T = W);
      else break e;
    }
  }
  function n(L) {
    return L.length === 0 ? null : L[0];
  }
  function r(L) {
    if (L.length === 0) return null;
    var M = L[0],
      T = L.pop();
    if (T !== M) {
      L[0] = T;
      e: for (var W = 0, q = L.length, cr = q >>> 1; W < cr; ) {
        var Ct = 2 * (W + 1) - 1,
          Rl = L[Ct],
          wt = Ct + 1,
          fr = L[wt];
        if (0 > l(Rl, T))
          wt < q && 0 > l(fr, Rl)
            ? ((L[W] = fr), (L[wt] = T), (W = wt))
            : ((L[W] = Rl), (L[Ct] = T), (W = Ct));
        else if (wt < q && 0 > l(fr, T)) (L[W] = fr), (L[wt] = T), (W = wt);
        else break e;
      }
    }
    return M;
  }
  function l(L, M) {
    var T = L.sortIndex - M.sortIndex;
    return T !== 0 ? T : L.id - M.id;
  }
  if (typeof performance == "object" && typeof performance.now == "function") {
    var i = performance;
    e.unstable_now = function () {
      return i.now();
    };
  } else {
    var o = Date,
      a = o.now();
    e.unstable_now = function () {
      return o.now() - a;
    };
  }
  var u = [],
    f = [],
    c = 1,
    h = null,
    v = 3,
    g = !1,
    x = !1,
    C = !1,
    j = typeof setTimeout == "function" ? setTimeout : null,
    p = typeof clearTimeout == "function" ? clearTimeout : null,
    d = typeof setImmediate < "u" ? setImmediate : null;
  typeof navigator < "u" &&
    navigator.scheduling !== void 0 &&
    navigator.scheduling.isInputPending !== void 0 &&
    navigator.scheduling.isInputPending.bind(navigator.scheduling);
  function m(L) {
    for (var M = n(f); M !== null; ) {
      if (M.callback === null) r(f);
      else if (M.startTime <= L)
        r(f), (M.sortIndex = M.expirationTime), t(u, M);
      else break;
      M = n(f);
    }
  }
  function y(L) {
    if (((C = !1), m(L), !x))
      if (n(u) !== null) (x = !0), Ml(E);
      else {
        var M = n(f);
        M !== null && Tl(y, M.startTime - L);
      }
  }
  function E(L, M) {
    (x = !1), C && ((C = !1), p(z), (z = -1)), (g = !0);
    var T = v;
    try {
      for (
        m(M), h = n(u);
        h !== null && (!(h.expirationTime > M) || (L && !J()));

      ) {
        var W = h.callback;
        if (typeof W == "function") {
          (h.callback = null), (v = h.priorityLevel);
          var q = W(h.expirationTime <= M);
          (M = e.unstable_now()),
            typeof q == "function" ? (h.callback = q) : h === n(u) && r(u),
            m(M);
        } else r(u);
        h = n(u);
      }
      if (h !== null) var cr = !0;
      else {
        var Ct = n(f);
        Ct !== null && Tl(y, Ct.startTime - M), (cr = !1);
      }
      return cr;
    } finally {
      (h = null), (v = T), (g = !1);
    }
  }
  var _ = !1,
    N = null,
    z = -1,
    I = 5,
    P = -1;
  function J() {
    return !(e.unstable_now() - P < I);
  }
  function yt() {
    if (N !== null) {
      var L = e.unstable_now();
      P = L;
      var M = !0;
      try {
        M = N(!0, L);
      } finally {
        M ? vn() : ((_ = !1), (N = null));
      }
    } else _ = !1;
  }
  var vn;
  if (typeof d == "function")
    vn = function () {
      d(yt);
    };
  else if (typeof MessageChannel < "u") {
    var ls = new MessageChannel(),
      i3 = ls.port2;
    (ls.port1.onmessage = yt),
      (vn = function () {
        i3.postMessage(null);
      });
  } else
    vn = function () {
      j(yt, 0);
    };
  function Ml(L) {
    (N = L), _ || ((_ = !0), vn());
  }
  function Tl(L, M) {
    z = j(function () {
      L(e.unstable_now());
    }, M);
  }
  (e.unstable_IdlePriority = 5),
    (e.unstable_ImmediatePriority = 1),
    (e.unstable_LowPriority = 4),
    (e.unstable_NormalPriority = 3),
    (e.unstable_Profiling = null),
    (e.unstable_UserBlockingPriority = 2),
    (e.unstable_cancelCallback = function (L) {
      L.callback = null;
    }),
    (e.unstable_continueExecution = function () {
      x || g || ((x = !0), Ml(E));
    }),
    (e.unstable_forceFrameRate = function (L) {
      0 > L || 125 < L
        ? console.error(
            "forceFrameRate takes a positive int between 0 and 125, forcing frame rates higher than 125 fps is not supported"
          )
        : (I = 0 < L ? Math.floor(1e3 / L) : 5);
    }),
    (e.unstable_getCurrentPriorityLevel = function () {
      return v;
    }),
    (e.unstable_getFirstCallbackNode = function () {
      return n(u);
    }),
    (e.unstable_next = function (L) {
      switch (v) {
        case 1:
        case 2:
        case 3:
          var M = 3;
          break;
        default:
          M = v;
      }
      var T = v;
      v = M;
      try {
        return L();
      } finally {
        v = T;
      }
    }),
    (e.unstable_pauseExecution = function () {}),
    (e.unstable_requestPaint = function () {}),
    (e.unstable_runWithPriority = function (L, M) {
      switch (L) {
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
          break;
        default:
          L = 3;
      }
      var T = v;
      v = L;
      try {
        return M();
      } finally {
        v = T;
      }
    }),
    (e.unstable_scheduleCallback = function (L, M, T) {
      var W = e.unstable_now();
      switch (
        (typeof T == "object" && T !== null
          ? ((T = T.delay), (T = typeof T == "number" && 0 < T ? W + T : W))
          : (T = W),
        L)
      ) {
        case 1:
          var q = -1;
          break;
        case 2:
          q = 250;
          break;
        case 5:
          q = 1073741823;
          break;
        case 4:
          q = 1e4;
          break;
        default:
          q = 5e3;
      }
      return (
        (q = T + q),
        (L = {
          id: c++,
          callback: M,
          priorityLevel: L,
          startTime: T,
          expirationTime: q,
          sortIndex: -1,
        }),
        T > W
          ? ((L.sortIndex = T),
            t(f, L),
            n(u) === null &&
              L === n(f) &&
              (C ? (p(z), (z = -1)) : (C = !0), Tl(y, T - W)))
          : ((L.sortIndex = q), t(u, L), x || g || ((x = !0), Ml(E))),
        L
      );
    }),
    (e.unstable_shouldYield = J),
    (e.unstable_wrapCallback = function (L) {
      var M = v;
      return function () {
        var T = v;
        v = M;
        try {
          return L.apply(this, arguments);
        } finally {
          v = T;
        }
      };
    });
})(Ba);
Fa.exports = Ba;
var P3 = Fa.exports;
/**
 * @license React
 * react-dom.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var Ia = S,
  Ce = P3;
function w(e) {
  for (
    var t = "https://reactjs.org/docs/error-decoder.html?invariant=" + e, n = 1;
    n < arguments.length;
    n++
  )
    t += "&args[]=" + encodeURIComponent(arguments[n]);
  return (
    "Minified React error #" +
    e +
    "; visit " +
    t +
    " for the full message or use the non-minified dev environment for full errors and additional helpful warnings."
  );
}
var $a = new Set(),
  $n = {};
function Ot(e, t) {
  nn(e, t), nn(e + "Capture", t);
}
function nn(e, t) {
  for ($n[e] = t, e = 0; e < t.length; e++) $a.add(t[e]);
}
var Ge = !(
    typeof window > "u" ||
    typeof window.document > "u" ||
    typeof window.document.createElement > "u"
  ),
  ui = Object.prototype.hasOwnProperty,
  z3 =
    /^[:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\-.0-9\u00B7\u0300-\u036F\u203F-\u2040]*$/,
  as = {},
  us = {};
function M3(e) {
  return ui.call(us, e)
    ? !0
    : ui.call(as, e)
    ? !1
    : z3.test(e)
    ? (us[e] = !0)
    : ((as[e] = !0), !1);
}
function T3(e, t, n, r) {
  if (n !== null && n.type === 0) return !1;
  switch (typeof t) {
    case "function":
    case "symbol":
      return !0;
    case "boolean":
      return r
        ? !1
        : n !== null
        ? !n.acceptsBooleans
        : ((e = e.toLowerCase().slice(0, 5)), e !== "data-" && e !== "aria-");
    default:
      return !1;
  }
}
function R3(e, t, n, r) {
  if (t === null || typeof t > "u" || T3(e, t, n, r)) return !0;
  if (r) return !1;
  if (n !== null)
    switch (n.type) {
      case 3:
        return !t;
      case 4:
        return t === !1;
      case 5:
        return isNaN(t);
      case 6:
        return isNaN(t) || 1 > t;
    }
  return !1;
}
function fe(e, t, n, r, l, i, o) {
  (this.acceptsBooleans = t === 2 || t === 3 || t === 4),
    (this.attributeName = r),
    (this.attributeNamespace = l),
    (this.mustUseProperty = n),
    (this.propertyName = e),
    (this.type = t),
    (this.sanitizeURL = i),
    (this.removeEmptyString = o);
}
var re = {};
"children dangerouslySetInnerHTML defaultValue defaultChecked innerHTML suppressContentEditableWarning suppressHydrationWarning style"
  .split(" ")
  .forEach(function (e) {
    re[e] = new fe(e, 0, !1, e, null, !1, !1);
  });
[
  ["acceptCharset", "accept-charset"],
  ["className", "class"],
  ["htmlFor", "for"],
  ["httpEquiv", "http-equiv"],
].forEach(function (e) {
  var t = e[0];
  re[t] = new fe(t, 1, !1, e[1], null, !1, !1);
});
["contentEditable", "draggable", "spellCheck", "value"].forEach(function (e) {
  re[e] = new fe(e, 2, !1, e.toLowerCase(), null, !1, !1);
});
[
  "autoReverse",
  "externalResourcesRequired",
  "focusable",
  "preserveAlpha",
].forEach(function (e) {
  re[e] = new fe(e, 2, !1, e, null, !1, !1);
});
"allowFullScreen async autoFocus autoPlay controls default defer disabled disablePictureInPicture disableRemotePlayback formNoValidate hidden loop noModule noValidate open playsInline readOnly required reversed scoped seamless itemScope"
  .split(" ")
  .forEach(function (e) {
    re[e] = new fe(e, 3, !1, e.toLowerCase(), null, !1, !1);
  });
["checked", "multiple", "muted", "selected"].forEach(function (e) {
  re[e] = new fe(e, 3, !0, e, null, !1, !1);
});
["capture", "download"].forEach(function (e) {
  re[e] = new fe(e, 4, !1, e, null, !1, !1);
});
["cols", "rows", "size", "span"].forEach(function (e) {
  re[e] = new fe(e, 6, !1, e, null, !1, !1);
});
["rowSpan", "start"].forEach(function (e) {
  re[e] = new fe(e, 5, !1, e.toLowerCase(), null, !1, !1);
});
var ao = /[\-:]([a-z])/g;
function uo(e) {
  return e[1].toUpperCase();
}
"accent-height alignment-baseline arabic-form baseline-shift cap-height clip-path clip-rule color-interpolation color-interpolation-filters color-profile color-rendering dominant-baseline enable-background fill-opacity fill-rule flood-color flood-opacity font-family font-size font-size-adjust font-stretch font-style font-variant font-weight glyph-name glyph-orientation-horizontal glyph-orientation-vertical horiz-adv-x horiz-origin-x image-rendering letter-spacing lighting-color marker-end marker-mid marker-start overline-position overline-thickness paint-order panose-1 pointer-events rendering-intent shape-rendering stop-color stop-opacity strikethrough-position strikethrough-thickness stroke-dasharray stroke-dashoffset stroke-linecap stroke-linejoin stroke-miterlimit stroke-opacity stroke-width text-anchor text-decoration text-rendering underline-position underline-thickness unicode-bidi unicode-range units-per-em v-alphabetic v-hanging v-ideographic v-mathematical vector-effect vert-adv-y vert-origin-x vert-origin-y word-spacing writing-mode xmlns:xlink x-height"
  .split(" ")
  .forEach(function (e) {
    var t = e.replace(ao, uo);
    re[t] = new fe(t, 1, !1, e, null, !1, !1);
  });
"xlink:actuate xlink:arcrole xlink:role xlink:show xlink:title xlink:type"
  .split(" ")
  .forEach(function (e) {
    var t = e.replace(ao, uo);
    re[t] = new fe(t, 1, !1, e, "http://www.w3.org/1999/xlink", !1, !1);
  });
["xml:base", "xml:lang", "xml:space"].forEach(function (e) {
  var t = e.replace(ao, uo);
  re[t] = new fe(t, 1, !1, e, "http://www.w3.org/XML/1998/namespace", !1, !1);
});
["tabIndex", "crossOrigin"].forEach(function (e) {
  re[e] = new fe(e, 1, !1, e.toLowerCase(), null, !1, !1);
});
re.xlinkHref = new fe(
  "xlinkHref",
  1,
  !1,
  "xlink:href",
  "http://www.w3.org/1999/xlink",
  !0,
  !1
);
["src", "href", "action", "formAction"].forEach(function (e) {
  re[e] = new fe(e, 1, !1, e.toLowerCase(), null, !0, !0);
});
function co(e, t, n, r) {
  var l = re.hasOwnProperty(t) ? re[t] : null;
  (l !== null
    ? l.type !== 0
    : r ||
      !(2 < t.length) ||
      (t[0] !== "o" && t[0] !== "O") ||
      (t[1] !== "n" && t[1] !== "N")) &&
    (R3(t, n, l, r) && (n = null),
    r || l === null
      ? M3(t) && (n === null ? e.removeAttribute(t) : e.setAttribute(t, "" + n))
      : l.mustUseProperty
      ? (e[l.propertyName] = n === null ? (l.type === 3 ? !1 : "") : n)
      : ((t = l.attributeName),
        (r = l.attributeNamespace),
        n === null
          ? e.removeAttribute(t)
          : ((l = l.type),
            (n = l === 3 || (l === 4 && n === !0) ? "" : "" + n),
            r ? e.setAttributeNS(r, t, n) : e.setAttribute(t, n))));
}
var Je = Ia.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED,
  pr = Symbol.for("react.element"),
  Bt = Symbol.for("react.portal"),
  It = Symbol.for("react.fragment"),
  fo = Symbol.for("react.strict_mode"),
  ci = Symbol.for("react.profiler"),
  Aa = Symbol.for("react.provider"),
  Va = Symbol.for("react.context"),
  po = Symbol.for("react.forward_ref"),
  fi = Symbol.for("react.suspense"),
  di = Symbol.for("react.suspense_list"),
  mo = Symbol.for("react.memo"),
  be = Symbol.for("react.lazy"),
  Ha = Symbol.for("react.offscreen"),
  cs = Symbol.iterator;
function gn(e) {
  return e === null || typeof e != "object"
    ? null
    : ((e = (cs && e[cs]) || e["@@iterator"]),
      typeof e == "function" ? e : null);
}
var H = Object.assign,
  Ol;
function kn(e) {
  if (Ol === void 0)
    try {
      throw Error();
    } catch (n) {
      var t = n.stack.trim().match(/\n( *(at )?)/);
      Ol = (t && t[1]) || "";
    }
  return (
    `
` +
    Ol +
    e
  );
}
var Ul = !1;
function Fl(e, t) {
  if (!e || Ul) return "";
  Ul = !0;
  var n = Error.prepareStackTrace;
  Error.prepareStackTrace = void 0;
  try {
    if (t)
      if (
        ((t = function () {
          throw Error();
        }),
        Object.defineProperty(t.prototype, "props", {
          set: function () {
            throw Error();
          },
        }),
        typeof Reflect == "object" && Reflect.construct)
      ) {
        try {
          Reflect.construct(t, []);
        } catch (f) {
          var r = f;
        }
        Reflect.construct(e, [], t);
      } else {
        try {
          t.call();
        } catch (f) {
          r = f;
        }
        e.call(t.prototype);
      }
    else {
      try {
        throw Error();
      } catch (f) {
        r = f;
      }
      e();
    }
  } catch (f) {
    if (f && r && typeof f.stack == "string") {
      for (
        var l = f.stack.split(`
`),
          i = r.stack.split(`
`),
          o = l.length - 1,
          a = i.length - 1;
        1 <= o && 0 <= a && l[o] !== i[a];

      )
        a--;
      for (; 1 <= o && 0 <= a; o--, a--)
        if (l[o] !== i[a]) {
          if (o !== 1 || a !== 1)
            do
              if ((o--, a--, 0 > a || l[o] !== i[a])) {
                var u =
                  `
` + l[o].replace(" at new ", " at ");
                return (
                  e.displayName &&
                    u.includes("<anonymous>") &&
                    (u = u.replace("<anonymous>", e.displayName)),
                  u
                );
              }
            while (1 <= o && 0 <= a);
          break;
        }
    }
  } finally {
    (Ul = !1), (Error.prepareStackTrace = n);
  }
  return (e = e ? e.displayName || e.name : "") ? kn(e) : "";
}
function D3(e) {
  switch (e.tag) {
    case 5:
      return kn(e.type);
    case 16:
      return kn("Lazy");
    case 13:
      return kn("Suspense");
    case 19:
      return kn("SuspenseList");
    case 0:
    case 2:
    case 15:
      return (e = Fl(e.type, !1)), e;
    case 11:
      return (e = Fl(e.type.render, !1)), e;
    case 1:
      return (e = Fl(e.type, !0)), e;
    default:
      return "";
  }
}
function pi(e) {
  if (e == null) return null;
  if (typeof e == "function") return e.displayName || e.name || null;
  if (typeof e == "string") return e;
  switch (e) {
    case It:
      return "Fragment";
    case Bt:
      return "Portal";
    case ci:
      return "Profiler";
    case fo:
      return "StrictMode";
    case fi:
      return "Suspense";
    case di:
      return "SuspenseList";
  }
  if (typeof e == "object")
    switch (e.$$typeof) {
      case Va:
        return (e.displayName || "Context") + ".Consumer";
      case Aa:
        return (e._context.displayName || "Context") + ".Provider";
      case po:
        var t = e.render;
        return (
          (e = e.displayName),
          e ||
            ((e = t.displayName || t.name || ""),
            (e = e !== "" ? "ForwardRef(" + e + ")" : "ForwardRef")),
          e
        );
      case mo:
        return (
          (t = e.displayName || null), t !== null ? t : pi(e.type) || "Memo"
        );
      case be:
        (t = e._payload), (e = e._init);
        try {
          return pi(e(t));
        } catch {}
    }
  return null;
}
function O3(e) {
  var t = e.type;
  switch (e.tag) {
    case 24:
      return "Cache";
    case 9:
      return (t.displayName || "Context") + ".Consumer";
    case 10:
      return (t._context.displayName || "Context") + ".Provider";
    case 18:
      return "DehydratedFragment";
    case 11:
      return (
        (e = t.render),
        (e = e.displayName || e.name || ""),
        t.displayName || (e !== "" ? "ForwardRef(" + e + ")" : "ForwardRef")
      );
    case 7:
      return "Fragment";
    case 5:
      return t;
    case 4:
      return "Portal";
    case 3:
      return "Root";
    case 6:
      return "Text";
    case 16:
      return pi(t);
    case 8:
      return t === fo ? "StrictMode" : "Mode";
    case 22:
      return "Offscreen";
    case 12:
      return "Profiler";
    case 21:
      return "Scope";
    case 13:
      return "Suspense";
    case 19:
      return "SuspenseList";
    case 25:
      return "TracingMarker";
    case 1:
    case 0:
    case 17:
    case 2:
    case 14:
    case 15:
      if (typeof t == "function") return t.displayName || t.name || null;
      if (typeof t == "string") return t;
  }
  return null;
}
function mt(e) {
  switch (typeof e) {
    case "boolean":
    case "number":
    case "string":
    case "undefined":
      return e;
    case "object":
      return e;
    default:
      return "";
  }
}
function Za(e) {
  var t = e.type;
  return (
    (e = e.nodeName) &&
    e.toLowerCase() === "input" &&
    (t === "checkbox" || t === "radio")
  );
}
function U3(e) {
  var t = Za(e) ? "checked" : "value",
    n = Object.getOwnPropertyDescriptor(e.constructor.prototype, t),
    r = "" + e[t];
  if (
    !e.hasOwnProperty(t) &&
    typeof n < "u" &&
    typeof n.get == "function" &&
    typeof n.set == "function"
  ) {
    var l = n.get,
      i = n.set;
    return (
      Object.defineProperty(e, t, {
        configurable: !0,
        get: function () {
          return l.call(this);
        },
        set: function (o) {
          (r = "" + o), i.call(this, o);
        },
      }),
      Object.defineProperty(e, t, { enumerable: n.enumerable }),
      {
        getValue: function () {
          return r;
        },
        setValue: function (o) {
          r = "" + o;
        },
        stopTracking: function () {
          (e._valueTracker = null), delete e[t];
        },
      }
    );
  }
}
function mr(e) {
  e._valueTracker || (e._valueTracker = U3(e));
}
function Wa(e) {
  if (!e) return !1;
  var t = e._valueTracker;
  if (!t) return !0;
  var n = t.getValue(),
    r = "";
  return (
    e && (r = Za(e) ? (e.checked ? "true" : "false") : e.value),
    (e = r),
    e !== n ? (t.setValue(e), !0) : !1
  );
}
function Ar(e) {
  if (((e = e || (typeof document < "u" ? document : void 0)), typeof e > "u"))
    return null;
  try {
    return e.activeElement || e.body;
  } catch {
    return e.body;
  }
}
function mi(e, t) {
  var n = t.checked;
  return H({}, t, {
    defaultChecked: void 0,
    defaultValue: void 0,
    value: void 0,
    checked: n ?? e._wrapperState.initialChecked,
  });
}
function fs(e, t) {
  var n = t.defaultValue == null ? "" : t.defaultValue,
    r = t.checked != null ? t.checked : t.defaultChecked;
  (n = mt(t.value != null ? t.value : n)),
    (e._wrapperState = {
      initialChecked: r,
      initialValue: n,
      controlled:
        t.type === "checkbox" || t.type === "radio"
          ? t.checked != null
          : t.value != null,
    });
}
function Qa(e, t) {
  (t = t.checked), t != null && co(e, "checked", t, !1);
}
function hi(e, t) {
  Qa(e, t);
  var n = mt(t.value),
    r = t.type;
  if (n != null)
    r === "number"
      ? ((n === 0 && e.value === "") || e.value != n) && (e.value = "" + n)
      : e.value !== "" + n && (e.value = "" + n);
  else if (r === "submit" || r === "reset") {
    e.removeAttribute("value");
    return;
  }
  t.hasOwnProperty("value")
    ? vi(e, t.type, n)
    : t.hasOwnProperty("defaultValue") && vi(e, t.type, mt(t.defaultValue)),
    t.checked == null &&
      t.defaultChecked != null &&
      (e.defaultChecked = !!t.defaultChecked);
}
function ds(e, t, n) {
  if (t.hasOwnProperty("value") || t.hasOwnProperty("defaultValue")) {
    var r = t.type;
    if (
      !(
        (r !== "submit" && r !== "reset") ||
        (t.value !== void 0 && t.value !== null)
      )
    )
      return;
    (t = "" + e._wrapperState.initialValue),
      n || t === e.value || (e.value = t),
      (e.defaultValue = t);
  }
  (n = e.name),
    n !== "" && (e.name = ""),
    (e.defaultChecked = !!e._wrapperState.initialChecked),
    n !== "" && (e.name = n);
}
function vi(e, t, n) {
  (t !== "number" || Ar(e.ownerDocument) !== e) &&
    (n == null
      ? (e.defaultValue = "" + e._wrapperState.initialValue)
      : e.defaultValue !== "" + n && (e.defaultValue = "" + n));
}
var Ln = Array.isArray;
function Xt(e, t, n, r) {
  if (((e = e.options), t)) {
    t = {};
    for (var l = 0; l < n.length; l++) t["$" + n[l]] = !0;
    for (n = 0; n < e.length; n++)
      (l = t.hasOwnProperty("$" + e[n].value)),
        e[n].selected !== l && (e[n].selected = l),
        l && r && (e[n].defaultSelected = !0);
  } else {
    for (n = "" + mt(n), t = null, l = 0; l < e.length; l++) {
      if (e[l].value === n) {
        (e[l].selected = !0), r && (e[l].defaultSelected = !0);
        return;
      }
      t !== null || e[l].disabled || (t = e[l]);
    }
    t !== null && (t.selected = !0);
  }
}
function gi(e, t) {
  if (t.dangerouslySetInnerHTML != null) throw Error(w(91));
  return H({}, t, {
    value: void 0,
    defaultValue: void 0,
    children: "" + e._wrapperState.initialValue,
  });
}
function ps(e, t) {
  var n = t.value;
  if (n == null) {
    if (((n = t.children), (t = t.defaultValue), n != null)) {
      if (t != null) throw Error(w(92));
      if (Ln(n)) {
        if (1 < n.length) throw Error(w(93));
        n = n[0];
      }
      t = n;
    }
    t == null && (t = ""), (n = t);
  }
  e._wrapperState = { initialValue: mt(n) };
}
function Ga(e, t) {
  var n = mt(t.value),
    r = mt(t.defaultValue);
  n != null &&
    ((n = "" + n),
    n !== e.value && (e.value = n),
    t.defaultValue == null && e.defaultValue !== n && (e.defaultValue = n)),
    r != null && (e.defaultValue = "" + r);
}
function ms(e) {
  var t = e.textContent;
  t === e._wrapperState.initialValue && t !== "" && t !== null && (e.value = t);
}
function Ka(e) {
  switch (e) {
    case "svg":
      return "http://www.w3.org/2000/svg";
    case "math":
      return "http://www.w3.org/1998/Math/MathML";
    default:
      return "http://www.w3.org/1999/xhtml";
  }
}
function xi(e, t) {
  return e == null || e === "http://www.w3.org/1999/xhtml"
    ? Ka(t)
    : e === "http://www.w3.org/2000/svg" && t === "foreignObject"
    ? "http://www.w3.org/1999/xhtml"
    : e;
}
var hr,
  Ya = (function (e) {
    return typeof MSApp < "u" && MSApp.execUnsafeLocalFunction
      ? function (t, n, r, l) {
          MSApp.execUnsafeLocalFunction(function () {
            return e(t, n, r, l);
          });
        }
      : e;
  })(function (e, t) {
    if (e.namespaceURI !== "http://www.w3.org/2000/svg" || "innerHTML" in e)
      e.innerHTML = t;
    else {
      for (
        hr = hr || document.createElement("div"),
          hr.innerHTML = "<svg>" + t.valueOf().toString() + "</svg>",
          t = hr.firstChild;
        e.firstChild;

      )
        e.removeChild(e.firstChild);
      for (; t.firstChild; ) e.appendChild(t.firstChild);
    }
  });
function An(e, t) {
  if (t) {
    var n = e.firstChild;
    if (n && n === e.lastChild && n.nodeType === 3) {
      n.nodeValue = t;
      return;
    }
  }
  e.textContent = t;
}
var Mn = {
    animationIterationCount: !0,
    aspectRatio: !0,
    borderImageOutset: !0,
    borderImageSlice: !0,
    borderImageWidth: !0,
    boxFlex: !0,
    boxFlexGroup: !0,
    boxOrdinalGroup: !0,
    columnCount: !0,
    columns: !0,
    flex: !0,
    flexGrow: !0,
    flexPositive: !0,
    flexShrink: !0,
    flexNegative: !0,
    flexOrder: !0,
    gridArea: !0,
    gridRow: !0,
    gridRowEnd: !0,
    gridRowSpan: !0,
    gridRowStart: !0,
    gridColumn: !0,
    gridColumnEnd: !0,
    gridColumnSpan: !0,
    gridColumnStart: !0,
    fontWeight: !0,
    lineClamp: !0,
    lineHeight: !0,
    opacity: !0,
    order: !0,
    orphans: !0,
    tabSize: !0,
    widows: !0,
    zIndex: !0,
    zoom: !0,
    fillOpacity: !0,
    floodOpacity: !0,
    stopOpacity: !0,
    strokeDasharray: !0,
    strokeDashoffset: !0,
    strokeMiterlimit: !0,
    strokeOpacity: !0,
    strokeWidth: !0,
  },
  F3 = ["Webkit", "ms", "Moz", "O"];
Object.keys(Mn).forEach(function (e) {
  F3.forEach(function (t) {
    (t = t + e.charAt(0).toUpperCase() + e.substring(1)), (Mn[t] = Mn[e]);
  });
});
function Xa(e, t, n) {
  return t == null || typeof t == "boolean" || t === ""
    ? ""
    : n || typeof t != "number" || t === 0 || (Mn.hasOwnProperty(e) && Mn[e])
    ? ("" + t).trim()
    : t + "px";
}
function Ja(e, t) {
  e = e.style;
  for (var n in t)
    if (t.hasOwnProperty(n)) {
      var r = n.indexOf("--") === 0,
        l = Xa(n, t[n], r);
      n === "float" && (n = "cssFloat"), r ? e.setProperty(n, l) : (e[n] = l);
    }
}
var B3 = H(
  { menuitem: !0 },
  {
    area: !0,
    base: !0,
    br: !0,
    col: !0,
    embed: !0,
    hr: !0,
    img: !0,
    input: !0,
    keygen: !0,
    link: !0,
    meta: !0,
    param: !0,
    source: !0,
    track: !0,
    wbr: !0,
  }
);
function yi(e, t) {
  if (t) {
    if (B3[e] && (t.children != null || t.dangerouslySetInnerHTML != null))
      throw Error(w(137, e));
    if (t.dangerouslySetInnerHTML != null) {
      if (t.children != null) throw Error(w(60));
      if (
        typeof t.dangerouslySetInnerHTML != "object" ||
        !("__html" in t.dangerouslySetInnerHTML)
      )
        throw Error(w(61));
    }
    if (t.style != null && typeof t.style != "object") throw Error(w(62));
  }
}
function Ci(e, t) {
  if (e.indexOf("-") === -1) return typeof t.is == "string";
  switch (e) {
    case "annotation-xml":
    case "color-profile":
    case "font-face":
    case "font-face-src":
    case "font-face-uri":
    case "font-face-format":
    case "font-face-name":
    case "missing-glyph":
      return !1;
    default:
      return !0;
  }
}
var wi = null;
function ho(e) {
  return (
    (e = e.target || e.srcElement || window),
    e.correspondingUseElement && (e = e.correspondingUseElement),
    e.nodeType === 3 ? e.parentNode : e
  );
}
var Si = null,
  Jt = null,
  qt = null;
function hs(e) {
  if ((e = ar(e))) {
    if (typeof Si != "function") throw Error(w(280));
    var t = e.stateNode;
    t && ((t = vl(t)), Si(e.stateNode, e.type, t));
  }
}
function qa(e) {
  Jt ? (qt ? qt.push(e) : (qt = [e])) : (Jt = e);
}
function ba() {
  if (Jt) {
    var e = Jt,
      t = qt;
    if (((qt = Jt = null), hs(e), t)) for (e = 0; e < t.length; e++) hs(t[e]);
  }
}
function eu(e, t) {
  return e(t);
}
function tu() {}
var Bl = !1;
function nu(e, t, n) {
  if (Bl) return e(t, n);
  Bl = !0;
  try {
    return eu(e, t, n);
  } finally {
    (Bl = !1), (Jt !== null || qt !== null) && (tu(), ba());
  }
}
function Vn(e, t) {
  var n = e.stateNode;
  if (n === null) return null;
  var r = vl(n);
  if (r === null) return null;
  n = r[t];
  e: switch (t) {
    case "onClick":
    case "onClickCapture":
    case "onDoubleClick":
    case "onDoubleClickCapture":
    case "onMouseDown":
    case "onMouseDownCapture":
    case "onMouseMove":
    case "onMouseMoveCapture":
    case "onMouseUp":
    case "onMouseUpCapture":
    case "onMouseEnter":
      (r = !r.disabled) ||
        ((e = e.type),
        (r = !(
          e === "button" ||
          e === "input" ||
          e === "select" ||
          e === "textarea"
        ))),
        (e = !r);
      break e;
    default:
      e = !1;
  }
  if (e) return null;
  if (n && typeof n != "function") throw Error(w(231, t, typeof n));
  return n;
}
var Ei = !1;
if (Ge)
  try {
    var xn = {};
    Object.defineProperty(xn, "passive", {
      get: function () {
        Ei = !0;
      },
    }),
      window.addEventListener("test", xn, xn),
      window.removeEventListener("test", xn, xn);
  } catch {
    Ei = !1;
  }
function I3(e, t, n, r, l, i, o, a, u) {
  var f = Array.prototype.slice.call(arguments, 3);
  try {
    t.apply(n, f);
  } catch (c) {
    this.onError(c);
  }
}
var Tn = !1,
  Vr = null,
  Hr = !1,
  ji = null,
  $3 = {
    onError: function (e) {
      (Tn = !0), (Vr = e);
    },
  };
function A3(e, t, n, r, l, i, o, a, u) {
  (Tn = !1), (Vr = null), I3.apply($3, arguments);
}
function V3(e, t, n, r, l, i, o, a, u) {
  if ((A3.apply(this, arguments), Tn)) {
    if (Tn) {
      var f = Vr;
      (Tn = !1), (Vr = null);
    } else throw Error(w(198));
    Hr || ((Hr = !0), (ji = f));
  }
}
function Ut(e) {
  var t = e,
    n = e;
  if (e.alternate) for (; t.return; ) t = t.return;
  else {
    e = t;
    do (t = e), t.flags & 4098 && (n = t.return), (e = t.return);
    while (e);
  }
  return t.tag === 3 ? n : null;
}
function ru(e) {
  if (e.tag === 13) {
    var t = e.memoizedState;
    if (
      (t === null && ((e = e.alternate), e !== null && (t = e.memoizedState)),
      t !== null)
    )
      return t.dehydrated;
  }
  return null;
}
function vs(e) {
  if (Ut(e) !== e) throw Error(w(188));
}
function H3(e) {
  var t = e.alternate;
  if (!t) {
    if (((t = Ut(e)), t === null)) throw Error(w(188));
    return t !== e ? null : e;
  }
  for (var n = e, r = t; ; ) {
    var l = n.return;
    if (l === null) break;
    var i = l.alternate;
    if (i === null) {
      if (((r = l.return), r !== null)) {
        n = r;
        continue;
      }
      break;
    }
    if (l.child === i.child) {
      for (i = l.child; i; ) {
        if (i === n) return vs(l), e;
        if (i === r) return vs(l), t;
        i = i.sibling;
      }
      throw Error(w(188));
    }
    if (n.return !== r.return) (n = l), (r = i);
    else {
      for (var o = !1, a = l.child; a; ) {
        if (a === n) {
          (o = !0), (n = l), (r = i);
          break;
        }
        if (a === r) {
          (o = !0), (r = l), (n = i);
          break;
        }
        a = a.sibling;
      }
      if (!o) {
        for (a = i.child; a; ) {
          if (a === n) {
            (o = !0), (n = i), (r = l);
            break;
          }
          if (a === r) {
            (o = !0), (r = i), (n = l);
            break;
          }
          a = a.sibling;
        }
        if (!o) throw Error(w(189));
      }
    }
    if (n.alternate !== r) throw Error(w(190));
  }
  if (n.tag !== 3) throw Error(w(188));
  return n.stateNode.current === n ? e : t;
}
function lu(e) {
  return (e = H3(e)), e !== null ? iu(e) : null;
}
function iu(e) {
  if (e.tag === 5 || e.tag === 6) return e;
  for (e = e.child; e !== null; ) {
    var t = iu(e);
    if (t !== null) return t;
    e = e.sibling;
  }
  return null;
}
var ou = Ce.unstable_scheduleCallback,
  gs = Ce.unstable_cancelCallback,
  Z3 = Ce.unstable_shouldYield,
  W3 = Ce.unstable_requestPaint,
  Q = Ce.unstable_now,
  Q3 = Ce.unstable_getCurrentPriorityLevel,
  vo = Ce.unstable_ImmediatePriority,
  su = Ce.unstable_UserBlockingPriority,
  Zr = Ce.unstable_NormalPriority,
  G3 = Ce.unstable_LowPriority,
  au = Ce.unstable_IdlePriority,
  dl = null,
  $e = null;
function K3(e) {
  if ($e && typeof $e.onCommitFiberRoot == "function")
    try {
      $e.onCommitFiberRoot(dl, e, void 0, (e.current.flags & 128) === 128);
    } catch {}
}
var Re = Math.clz32 ? Math.clz32 : J3,
  Y3 = Math.log,
  X3 = Math.LN2;
function J3(e) {
  return (e >>>= 0), e === 0 ? 32 : (31 - ((Y3(e) / X3) | 0)) | 0;
}
var vr = 64,
  gr = 4194304;
function _n(e) {
  switch (e & -e) {
    case 1:
      return 1;
    case 2:
      return 2;
    case 4:
      return 4;
    case 8:
      return 8;
    case 16:
      return 16;
    case 32:
      return 32;
    case 64:
    case 128:
    case 256:
    case 512:
    case 1024:
    case 2048:
    case 4096:
    case 8192:
    case 16384:
    case 32768:
    case 65536:
    case 131072:
    case 262144:
    case 524288:
    case 1048576:
    case 2097152:
      return e & 4194240;
    case 4194304:
    case 8388608:
    case 16777216:
    case 33554432:
    case 67108864:
      return e & 130023424;
    case 134217728:
      return 134217728;
    case 268435456:
      return 268435456;
    case 536870912:
      return 536870912;
    case 1073741824:
      return 1073741824;
    default:
      return e;
  }
}
function Wr(e, t) {
  var n = e.pendingLanes;
  if (n === 0) return 0;
  var r = 0,
    l = e.suspendedLanes,
    i = e.pingedLanes,
    o = n & 268435455;
  if (o !== 0) {
    var a = o & ~l;
    a !== 0 ? (r = _n(a)) : ((i &= o), i !== 0 && (r = _n(i)));
  } else (o = n & ~l), o !== 0 ? (r = _n(o)) : i !== 0 && (r = _n(i));
  if (r === 0) return 0;
  if (
    t !== 0 &&
    t !== r &&
    !(t & l) &&
    ((l = r & -r), (i = t & -t), l >= i || (l === 16 && (i & 4194240) !== 0))
  )
    return t;
  if ((r & 4 && (r |= n & 16), (t = e.entangledLanes), t !== 0))
    for (e = e.entanglements, t &= r; 0 < t; )
      (n = 31 - Re(t)), (l = 1 << n), (r |= e[n]), (t &= ~l);
  return r;
}
function q3(e, t) {
  switch (e) {
    case 1:
    case 2:
    case 4:
      return t + 250;
    case 8:
    case 16:
    case 32:
    case 64:
    case 128:
    case 256:
    case 512:
    case 1024:
    case 2048:
    case 4096:
    case 8192:
    case 16384:
    case 32768:
    case 65536:
    case 131072:
    case 262144:
    case 524288:
    case 1048576:
    case 2097152:
      return t + 5e3;
    case 4194304:
    case 8388608:
    case 16777216:
    case 33554432:
    case 67108864:
      return -1;
    case 134217728:
    case 268435456:
    case 536870912:
    case 1073741824:
      return -1;
    default:
      return -1;
  }
}
function b3(e, t) {
  for (
    var n = e.suspendedLanes,
      r = e.pingedLanes,
      l = e.expirationTimes,
      i = e.pendingLanes;
    0 < i;

  ) {
    var o = 31 - Re(i),
      a = 1 << o,
      u = l[o];
    u === -1
      ? (!(a & n) || a & r) && (l[o] = q3(a, t))
      : u <= t && (e.expiredLanes |= a),
      (i &= ~a);
  }
}
function ki(e) {
  return (
    (e = e.pendingLanes & -1073741825),
    e !== 0 ? e : e & 1073741824 ? 1073741824 : 0
  );
}
function uu() {
  var e = vr;
  return (vr <<= 1), !(vr & 4194240) && (vr = 64), e;
}
function Il(e) {
  for (var t = [], n = 0; 31 > n; n++) t.push(e);
  return t;
}
function or(e, t, n) {
  (e.pendingLanes |= t),
    t !== 536870912 && ((e.suspendedLanes = 0), (e.pingedLanes = 0)),
    (e = e.eventTimes),
    (t = 31 - Re(t)),
    (e[t] = n);
}
function e0(e, t) {
  var n = e.pendingLanes & ~t;
  (e.pendingLanes = t),
    (e.suspendedLanes = 0),
    (e.pingedLanes = 0),
    (e.expiredLanes &= t),
    (e.mutableReadLanes &= t),
    (e.entangledLanes &= t),
    (t = e.entanglements);
  var r = e.eventTimes;
  for (e = e.expirationTimes; 0 < n; ) {
    var l = 31 - Re(n),
      i = 1 << l;
    (t[l] = 0), (r[l] = -1), (e[l] = -1), (n &= ~i);
  }
}
function go(e, t) {
  var n = (e.entangledLanes |= t);
  for (e = e.entanglements; n; ) {
    var r = 31 - Re(n),
      l = 1 << r;
    (l & t) | (e[r] & t) && (e[r] |= t), (n &= ~l);
  }
}
var O = 0;
function cu(e) {
  return (e &= -e), 1 < e ? (4 < e ? (e & 268435455 ? 16 : 536870912) : 4) : 1;
}
var fu,
  xo,
  du,
  pu,
  mu,
  Li = !1,
  xr = [],
  ot = null,
  st = null,
  at = null,
  Hn = new Map(),
  Zn = new Map(),
  tt = [],
  t0 =
    "mousedown mouseup touchcancel touchend touchstart auxclick dblclick pointercancel pointerdown pointerup dragend dragstart drop compositionend compositionstart keydown keypress keyup input textInput copy cut paste click change contextmenu reset submit".split(
      " "
    );
function xs(e, t) {
  switch (e) {
    case "focusin":
    case "focusout":
      ot = null;
      break;
    case "dragenter":
    case "dragleave":
      st = null;
      break;
    case "mouseover":
    case "mouseout":
      at = null;
      break;
    case "pointerover":
    case "pointerout":
      Hn.delete(t.pointerId);
      break;
    case "gotpointercapture":
    case "lostpointercapture":
      Zn.delete(t.pointerId);
  }
}
function yn(e, t, n, r, l, i) {
  return e === null || e.nativeEvent !== i
    ? ((e = {
        blockedOn: t,
        domEventName: n,
        eventSystemFlags: r,
        nativeEvent: i,
        targetContainers: [l],
      }),
      t !== null && ((t = ar(t)), t !== null && xo(t)),
      e)
    : ((e.eventSystemFlags |= r),
      (t = e.targetContainers),
      l !== null && t.indexOf(l) === -1 && t.push(l),
      e);
}
function n0(e, t, n, r, l) {
  switch (t) {
    case "focusin":
      return (ot = yn(ot, e, t, n, r, l)), !0;
    case "dragenter":
      return (st = yn(st, e, t, n, r, l)), !0;
    case "mouseover":
      return (at = yn(at, e, t, n, r, l)), !0;
    case "pointerover":
      var i = l.pointerId;
      return Hn.set(i, yn(Hn.get(i) || null, e, t, n, r, l)), !0;
    case "gotpointercapture":
      return (
        (i = l.pointerId), Zn.set(i, yn(Zn.get(i) || null, e, t, n, r, l)), !0
      );
  }
  return !1;
}
function hu(e) {
  var t = jt(e.target);
  if (t !== null) {
    var n = Ut(t);
    if (n !== null) {
      if (((t = n.tag), t === 13)) {
        if (((t = ru(n)), t !== null)) {
          (e.blockedOn = t),
            mu(e.priority, function () {
              du(n);
            });
          return;
        }
      } else if (t === 3 && n.stateNode.current.memoizedState.isDehydrated) {
        e.blockedOn = n.tag === 3 ? n.stateNode.containerInfo : null;
        return;
      }
    }
  }
  e.blockedOn = null;
}
function Mr(e) {
  if (e.blockedOn !== null) return !1;
  for (var t = e.targetContainers; 0 < t.length; ) {
    var n = _i(e.domEventName, e.eventSystemFlags, t[0], e.nativeEvent);
    if (n === null) {
      n = e.nativeEvent;
      var r = new n.constructor(n.type, n);
      (wi = r), n.target.dispatchEvent(r), (wi = null);
    } else return (t = ar(n)), t !== null && xo(t), (e.blockedOn = n), !1;
    t.shift();
  }
  return !0;
}
function ys(e, t, n) {
  Mr(e) && n.delete(t);
}
function r0() {
  (Li = !1),
    ot !== null && Mr(ot) && (ot = null),
    st !== null && Mr(st) && (st = null),
    at !== null && Mr(at) && (at = null),
    Hn.forEach(ys),
    Zn.forEach(ys);
}
function Cn(e, t) {
  e.blockedOn === t &&
    ((e.blockedOn = null),
    Li ||
      ((Li = !0),
      Ce.unstable_scheduleCallback(Ce.unstable_NormalPriority, r0)));
}
function Wn(e) {
  function t(l) {
    return Cn(l, e);
  }
  if (0 < xr.length) {
    Cn(xr[0], e);
    for (var n = 1; n < xr.length; n++) {
      var r = xr[n];
      r.blockedOn === e && (r.blockedOn = null);
    }
  }
  for (
    ot !== null && Cn(ot, e),
      st !== null && Cn(st, e),
      at !== null && Cn(at, e),
      Hn.forEach(t),
      Zn.forEach(t),
      n = 0;
    n < tt.length;
    n++
  )
    (r = tt[n]), r.blockedOn === e && (r.blockedOn = null);
  for (; 0 < tt.length && ((n = tt[0]), n.blockedOn === null); )
    hu(n), n.blockedOn === null && tt.shift();
}
var bt = Je.ReactCurrentBatchConfig,
  Qr = !0;
function l0(e, t, n, r) {
  var l = O,
    i = bt.transition;
  bt.transition = null;
  try {
    (O = 1), yo(e, t, n, r);
  } finally {
    (O = l), (bt.transition = i);
  }
}
function i0(e, t, n, r) {
  var l = O,
    i = bt.transition;
  bt.transition = null;
  try {
    (O = 4), yo(e, t, n, r);
  } finally {
    (O = l), (bt.transition = i);
  }
}
function yo(e, t, n, r) {
  if (Qr) {
    var l = _i(e, t, n, r);
    if (l === null) Yl(e, t, r, Gr, n), xs(e, r);
    else if (n0(l, e, t, n, r)) r.stopPropagation();
    else if ((xs(e, r), t & 4 && -1 < t0.indexOf(e))) {
      for (; l !== null; ) {
        var i = ar(l);
        if (
          (i !== null && fu(i),
          (i = _i(e, t, n, r)),
          i === null && Yl(e, t, r, Gr, n),
          i === l)
        )
          break;
        l = i;
      }
      l !== null && r.stopPropagation();
    } else Yl(e, t, r, null, n);
  }
}
var Gr = null;
function _i(e, t, n, r) {
  if (((Gr = null), (e = ho(r)), (e = jt(e)), e !== null))
    if (((t = Ut(e)), t === null)) e = null;
    else if (((n = t.tag), n === 13)) {
      if (((e = ru(t)), e !== null)) return e;
      e = null;
    } else if (n === 3) {
      if (t.stateNode.current.memoizedState.isDehydrated)
        return t.tag === 3 ? t.stateNode.containerInfo : null;
      e = null;
    } else t !== e && (e = null);
  return (Gr = e), null;
}
function vu(e) {
  switch (e) {
    case "cancel":
    case "click":
    case "close":
    case "contextmenu":
    case "copy":
    case "cut":
    case "auxclick":
    case "dblclick":
    case "dragend":
    case "dragstart":
    case "drop":
    case "focusin":
    case "focusout":
    case "input":
    case "invalid":
    case "keydown":
    case "keypress":
    case "keyup":
    case "mousedown":
    case "mouseup":
    case "paste":
    case "pause":
    case "play":
    case "pointercancel":
    case "pointerdown":
    case "pointerup":
    case "ratechange":
    case "reset":
    case "resize":
    case "seeked":
    case "submit":
    case "touchcancel":
    case "touchend":
    case "touchstart":
    case "volumechange":
    case "change":
    case "selectionchange":
    case "textInput":
    case "compositionstart":
    case "compositionend":
    case "compositionupdate":
    case "beforeblur":
    case "afterblur":
    case "beforeinput":
    case "blur":
    case "fullscreenchange":
    case "focus":
    case "hashchange":
    case "popstate":
    case "select":
    case "selectstart":
      return 1;
    case "drag":
    case "dragenter":
    case "dragexit":
    case "dragleave":
    case "dragover":
    case "mousemove":
    case "mouseout":
    case "mouseover":
    case "pointermove":
    case "pointerout":
    case "pointerover":
    case "scroll":
    case "toggle":
    case "touchmove":
    case "wheel":
    case "mouseenter":
    case "mouseleave":
    case "pointerenter":
    case "pointerleave":
      return 4;
    case "message":
      switch (Q3()) {
        case vo:
          return 1;
        case su:
          return 4;
        case Zr:
        case G3:
          return 16;
        case au:
          return 536870912;
        default:
          return 16;
      }
    default:
      return 16;
  }
}
var rt = null,
  Co = null,
  Tr = null;
function gu() {
  if (Tr) return Tr;
  var e,
    t = Co,
    n = t.length,
    r,
    l = "value" in rt ? rt.value : rt.textContent,
    i = l.length;
  for (e = 0; e < n && t[e] === l[e]; e++);
  var o = n - e;
  for (r = 1; r <= o && t[n - r] === l[i - r]; r++);
  return (Tr = l.slice(e, 1 < r ? 1 - r : void 0));
}
function Rr(e) {
  var t = e.keyCode;
  return (
    "charCode" in e
      ? ((e = e.charCode), e === 0 && t === 13 && (e = 13))
      : (e = t),
    e === 10 && (e = 13),
    32 <= e || e === 13 ? e : 0
  );
}
function yr() {
  return !0;
}
function Cs() {
  return !1;
}
function Se(e) {
  function t(n, r, l, i, o) {
    (this._reactName = n),
      (this._targetInst = l),
      (this.type = r),
      (this.nativeEvent = i),
      (this.target = o),
      (this.currentTarget = null);
    for (var a in e)
      e.hasOwnProperty(a) && ((n = e[a]), (this[a] = n ? n(i) : i[a]));
    return (
      (this.isDefaultPrevented = (
        i.defaultPrevented != null ? i.defaultPrevented : i.returnValue === !1
      )
        ? yr
        : Cs),
      (this.isPropagationStopped = Cs),
      this
    );
  }
  return (
    H(t.prototype, {
      preventDefault: function () {
        this.defaultPrevented = !0;
        var n = this.nativeEvent;
        n &&
          (n.preventDefault
            ? n.preventDefault()
            : typeof n.returnValue != "unknown" && (n.returnValue = !1),
          (this.isDefaultPrevented = yr));
      },
      stopPropagation: function () {
        var n = this.nativeEvent;
        n &&
          (n.stopPropagation
            ? n.stopPropagation()
            : typeof n.cancelBubble != "unknown" && (n.cancelBubble = !0),
          (this.isPropagationStopped = yr));
      },
      persist: function () {},
      isPersistent: yr,
    }),
    t
  );
}
var dn = {
    eventPhase: 0,
    bubbles: 0,
    cancelable: 0,
    timeStamp: function (e) {
      return e.timeStamp || Date.now();
    },
    defaultPrevented: 0,
    isTrusted: 0,
  },
  wo = Se(dn),
  sr = H({}, dn, { view: 0, detail: 0 }),
  o0 = Se(sr),
  $l,
  Al,
  wn,
  pl = H({}, sr, {
    screenX: 0,
    screenY: 0,
    clientX: 0,
    clientY: 0,
    pageX: 0,
    pageY: 0,
    ctrlKey: 0,
    shiftKey: 0,
    altKey: 0,
    metaKey: 0,
    getModifierState: So,
    button: 0,
    buttons: 0,
    relatedTarget: function (e) {
      return e.relatedTarget === void 0
        ? e.fromElement === e.srcElement
          ? e.toElement
          : e.fromElement
        : e.relatedTarget;
    },
    movementX: function (e) {
      return "movementX" in e
        ? e.movementX
        : (e !== wn &&
            (wn && e.type === "mousemove"
              ? (($l = e.screenX - wn.screenX), (Al = e.screenY - wn.screenY))
              : (Al = $l = 0),
            (wn = e)),
          $l);
    },
    movementY: function (e) {
      return "movementY" in e ? e.movementY : Al;
    },
  }),
  ws = Se(pl),
  s0 = H({}, pl, { dataTransfer: 0 }),
  a0 = Se(s0),
  u0 = H({}, sr, { relatedTarget: 0 }),
  Vl = Se(u0),
  c0 = H({}, dn, { animationName: 0, elapsedTime: 0, pseudoElement: 0 }),
  f0 = Se(c0),
  d0 = H({}, dn, {
    clipboardData: function (e) {
      return "clipboardData" in e ? e.clipboardData : window.clipboardData;
    },
  }),
  p0 = Se(d0),
  m0 = H({}, dn, { data: 0 }),
  Ss = Se(m0),
  h0 = {
    Esc: "Escape",
    Spacebar: " ",
    Left: "ArrowLeft",
    Up: "ArrowUp",
    Right: "ArrowRight",
    Down: "ArrowDown",
    Del: "Delete",
    Win: "OS",
    Menu: "ContextMenu",
    Apps: "ContextMenu",
    Scroll: "ScrollLock",
    MozPrintableKey: "Unidentified",
  },
  v0 = {
    8: "Backspace",
    9: "Tab",
    12: "Clear",
    13: "Enter",
    16: "Shift",
    17: "Control",
    18: "Alt",
    19: "Pause",
    20: "CapsLock",
    27: "Escape",
    32: " ",
    33: "PageUp",
    34: "PageDown",
    35: "End",
    36: "Home",
    37: "ArrowLeft",
    38: "ArrowUp",
    39: "ArrowRight",
    40: "ArrowDown",
    45: "Insert",
    46: "Delete",
    112: "F1",
    113: "F2",
    114: "F3",
    115: "F4",
    116: "F5",
    117: "F6",
    118: "F7",
    119: "F8",
    120: "F9",
    121: "F10",
    122: "F11",
    123: "F12",
    144: "NumLock",
    145: "ScrollLock",
    224: "Meta",
  },
  g0 = {
    Alt: "altKey",
    Control: "ctrlKey",
    Meta: "metaKey",
    Shift: "shiftKey",
  };
function x0(e) {
  var t = this.nativeEvent;
  return t.getModifierState ? t.getModifierState(e) : (e = g0[e]) ? !!t[e] : !1;
}
function So() {
  return x0;
}
var y0 = H({}, sr, {
    key: function (e) {
      if (e.key) {
        var t = h0[e.key] || e.key;
        if (t !== "Unidentified") return t;
      }
      return e.type === "keypress"
        ? ((e = Rr(e)), e === 13 ? "Enter" : String.fromCharCode(e))
        : e.type === "keydown" || e.type === "keyup"
        ? v0[e.keyCode] || "Unidentified"
        : "";
    },
    code: 0,
    location: 0,
    ctrlKey: 0,
    shiftKey: 0,
    altKey: 0,
    metaKey: 0,
    repeat: 0,
    locale: 0,
    getModifierState: So,
    charCode: function (e) {
      return e.type === "keypress" ? Rr(e) : 0;
    },
    keyCode: function (e) {
      return e.type === "keydown" || e.type === "keyup" ? e.keyCode : 0;
    },
    which: function (e) {
      return e.type === "keypress"
        ? Rr(e)
        : e.type === "keydown" || e.type === "keyup"
        ? e.keyCode
        : 0;
    },
  }),
  C0 = Se(y0),
  w0 = H({}, pl, {
    pointerId: 0,
    width: 0,
    height: 0,
    pressure: 0,
    tangentialPressure: 0,
    tiltX: 0,
    tiltY: 0,
    twist: 0,
    pointerType: 0,
    isPrimary: 0,
  }),
  Es = Se(w0),
  S0 = H({}, sr, {
    touches: 0,
    targetTouches: 0,
    changedTouches: 0,
    altKey: 0,
    metaKey: 0,
    ctrlKey: 0,
    shiftKey: 0,
    getModifierState: So,
  }),
  E0 = Se(S0),
  j0 = H({}, dn, { propertyName: 0, elapsedTime: 0, pseudoElement: 0 }),
  k0 = Se(j0),
  L0 = H({}, pl, {
    deltaX: function (e) {
      return "deltaX" in e ? e.deltaX : "wheelDeltaX" in e ? -e.wheelDeltaX : 0;
    },
    deltaY: function (e) {
      return "deltaY" in e
        ? e.deltaY
        : "wheelDeltaY" in e
        ? -e.wheelDeltaY
        : "wheelDelta" in e
        ? -e.wheelDelta
        : 0;
    },
    deltaZ: 0,
    deltaMode: 0,
  }),
  _0 = Se(L0),
  N0 = [9, 13, 27, 32],
  Eo = Ge && "CompositionEvent" in window,
  Rn = null;
Ge && "documentMode" in document && (Rn = document.documentMode);
var P0 = Ge && "TextEvent" in window && !Rn,
  xu = Ge && (!Eo || (Rn && 8 < Rn && 11 >= Rn)),
  js = " ",
  ks = !1;
function yu(e, t) {
  switch (e) {
    case "keyup":
      return N0.indexOf(t.keyCode) !== -1;
    case "keydown":
      return t.keyCode !== 229;
    case "keypress":
    case "mousedown":
    case "focusout":
      return !0;
    default:
      return !1;
  }
}
function Cu(e) {
  return (e = e.detail), typeof e == "object" && "data" in e ? e.data : null;
}
var $t = !1;
function z0(e, t) {
  switch (e) {
    case "compositionend":
      return Cu(t);
    case "keypress":
      return t.which !== 32 ? null : ((ks = !0), js);
    case "textInput":
      return (e = t.data), e === js && ks ? null : e;
    default:
      return null;
  }
}
function M0(e, t) {
  if ($t)
    return e === "compositionend" || (!Eo && yu(e, t))
      ? ((e = gu()), (Tr = Co = rt = null), ($t = !1), e)
      : null;
  switch (e) {
    case "paste":
      return null;
    case "keypress":
      if (!(t.ctrlKey || t.altKey || t.metaKey) || (t.ctrlKey && t.altKey)) {
        if (t.char && 1 < t.char.length) return t.char;
        if (t.which) return String.fromCharCode(t.which);
      }
      return null;
    case "compositionend":
      return xu && t.locale !== "ko" ? null : t.data;
    default:
      return null;
  }
}
var T0 = {
  color: !0,
  date: !0,
  datetime: !0,
  "datetime-local": !0,
  email: !0,
  month: !0,
  number: !0,
  password: !0,
  range: !0,
  search: !0,
  tel: !0,
  text: !0,
  time: !0,
  url: !0,
  week: !0,
};
function Ls(e) {
  var t = e && e.nodeName && e.nodeName.toLowerCase();
  return t === "input" ? !!T0[e.type] : t === "textarea";
}
function wu(e, t, n, r) {
  qa(r),
    (t = Kr(t, "onChange")),
    0 < t.length &&
      ((n = new wo("onChange", "change", null, n, r)),
      e.push({ event: n, listeners: t }));
}
var Dn = null,
  Qn = null;
function R0(e) {
  Tu(e, 0);
}
function ml(e) {
  var t = Ht(e);
  if (Wa(t)) return e;
}
function D0(e, t) {
  if (e === "change") return t;
}
var Su = !1;
if (Ge) {
  var Hl;
  if (Ge) {
    var Zl = "oninput" in document;
    if (!Zl) {
      var _s = document.createElement("div");
      _s.setAttribute("oninput", "return;"),
        (Zl = typeof _s.oninput == "function");
    }
    Hl = Zl;
  } else Hl = !1;
  Su = Hl && (!document.documentMode || 9 < document.documentMode);
}
function Ns() {
  Dn && (Dn.detachEvent("onpropertychange", Eu), (Qn = Dn = null));
}
function Eu(e) {
  if (e.propertyName === "value" && ml(Qn)) {
    var t = [];
    wu(t, Qn, e, ho(e)), nu(R0, t);
  }
}
function O0(e, t, n) {
  e === "focusin"
    ? (Ns(), (Dn = t), (Qn = n), Dn.attachEvent("onpropertychange", Eu))
    : e === "focusout" && Ns();
}
function U0(e) {
  if (e === "selectionchange" || e === "keyup" || e === "keydown")
    return ml(Qn);
}
function F0(e, t) {
  if (e === "click") return ml(t);
}
function B0(e, t) {
  if (e === "input" || e === "change") return ml(t);
}
function I0(e, t) {
  return (e === t && (e !== 0 || 1 / e === 1 / t)) || (e !== e && t !== t);
}
var Ue = typeof Object.is == "function" ? Object.is : I0;
function Gn(e, t) {
  if (Ue(e, t)) return !0;
  if (typeof e != "object" || e === null || typeof t != "object" || t === null)
    return !1;
  var n = Object.keys(e),
    r = Object.keys(t);
  if (n.length !== r.length) return !1;
  for (r = 0; r < n.length; r++) {
    var l = n[r];
    if (!ui.call(t, l) || !Ue(e[l], t[l])) return !1;
  }
  return !0;
}
function Ps(e) {
  for (; e && e.firstChild; ) e = e.firstChild;
  return e;
}
function zs(e, t) {
  var n = Ps(e);
  e = 0;
  for (var r; n; ) {
    if (n.nodeType === 3) {
      if (((r = e + n.textContent.length), e <= t && r >= t))
        return { node: n, offset: t - e };
      e = r;
    }
    e: {
      for (; n; ) {
        if (n.nextSibling) {
          n = n.nextSibling;
          break e;
        }
        n = n.parentNode;
      }
      n = void 0;
    }
    n = Ps(n);
  }
}
function ju(e, t) {
  return e && t
    ? e === t
      ? !0
      : e && e.nodeType === 3
      ? !1
      : t && t.nodeType === 3
      ? ju(e, t.parentNode)
      : "contains" in e
      ? e.contains(t)
      : e.compareDocumentPosition
      ? !!(e.compareDocumentPosition(t) & 16)
      : !1
    : !1;
}
function ku() {
  for (var e = window, t = Ar(); t instanceof e.HTMLIFrameElement; ) {
    try {
      var n = typeof t.contentWindow.location.href == "string";
    } catch {
      n = !1;
    }
    if (n) e = t.contentWindow;
    else break;
    t = Ar(e.document);
  }
  return t;
}
function jo(e) {
  var t = e && e.nodeName && e.nodeName.toLowerCase();
  return (
    t &&
    ((t === "input" &&
      (e.type === "text" ||
        e.type === "search" ||
        e.type === "tel" ||
        e.type === "url" ||
        e.type === "password")) ||
      t === "textarea" ||
      e.contentEditable === "true")
  );
}
function $0(e) {
  var t = ku(),
    n = e.focusedElem,
    r = e.selectionRange;
  if (
    t !== n &&
    n &&
    n.ownerDocument &&
    ju(n.ownerDocument.documentElement, n)
  ) {
    if (r !== null && jo(n)) {
      if (
        ((t = r.start),
        (e = r.end),
        e === void 0 && (e = t),
        "selectionStart" in n)
      )
        (n.selectionStart = t), (n.selectionEnd = Math.min(e, n.value.length));
      else if (
        ((e = ((t = n.ownerDocument || document) && t.defaultView) || window),
        e.getSelection)
      ) {
        e = e.getSelection();
        var l = n.textContent.length,
          i = Math.min(r.start, l);
        (r = r.end === void 0 ? i : Math.min(r.end, l)),
          !e.extend && i > r && ((l = r), (r = i), (i = l)),
          (l = zs(n, i));
        var o = zs(n, r);
        l &&
          o &&
          (e.rangeCount !== 1 ||
            e.anchorNode !== l.node ||
            e.anchorOffset !== l.offset ||
            e.focusNode !== o.node ||
            e.focusOffset !== o.offset) &&
          ((t = t.createRange()),
          t.setStart(l.node, l.offset),
          e.removeAllRanges(),
          i > r
            ? (e.addRange(t), e.extend(o.node, o.offset))
            : (t.setEnd(o.node, o.offset), e.addRange(t)));
      }
    }
    for (t = [], e = n; (e = e.parentNode); )
      e.nodeType === 1 &&
        t.push({ element: e, left: e.scrollLeft, top: e.scrollTop });
    for (typeof n.focus == "function" && n.focus(), n = 0; n < t.length; n++)
      (e = t[n]),
        (e.element.scrollLeft = e.left),
        (e.element.scrollTop = e.top);
  }
}
var A0 = Ge && "documentMode" in document && 11 >= document.documentMode,
  At = null,
  Ni = null,
  On = null,
  Pi = !1;
function Ms(e, t, n) {
  var r = n.window === n ? n.document : n.nodeType === 9 ? n : n.ownerDocument;
  Pi ||
    At == null ||
    At !== Ar(r) ||
    ((r = At),
    "selectionStart" in r && jo(r)
      ? (r = { start: r.selectionStart, end: r.selectionEnd })
      : ((r = (
          (r.ownerDocument && r.ownerDocument.defaultView) ||
          window
        ).getSelection()),
        (r = {
          anchorNode: r.anchorNode,
          anchorOffset: r.anchorOffset,
          focusNode: r.focusNode,
          focusOffset: r.focusOffset,
        })),
    (On && Gn(On, r)) ||
      ((On = r),
      (r = Kr(Ni, "onSelect")),
      0 < r.length &&
        ((t = new wo("onSelect", "select", null, t, n)),
        e.push({ event: t, listeners: r }),
        (t.target = At))));
}
function Cr(e, t) {
  var n = {};
  return (
    (n[e.toLowerCase()] = t.toLowerCase()),
    (n["Webkit" + e] = "webkit" + t),
    (n["Moz" + e] = "moz" + t),
    n
  );
}
var Vt = {
    animationend: Cr("Animation", "AnimationEnd"),
    animationiteration: Cr("Animation", "AnimationIteration"),
    animationstart: Cr("Animation", "AnimationStart"),
    transitionend: Cr("Transition", "TransitionEnd"),
  },
  Wl = {},
  Lu = {};
Ge &&
  ((Lu = document.createElement("div").style),
  "AnimationEvent" in window ||
    (delete Vt.animationend.animation,
    delete Vt.animationiteration.animation,
    delete Vt.animationstart.animation),
  "TransitionEvent" in window || delete Vt.transitionend.transition);
function hl(e) {
  if (Wl[e]) return Wl[e];
  if (!Vt[e]) return e;
  var t = Vt[e],
    n;
  for (n in t) if (t.hasOwnProperty(n) && n in Lu) return (Wl[e] = t[n]);
  return e;
}
var _u = hl("animationend"),
  Nu = hl("animationiteration"),
  Pu = hl("animationstart"),
  zu = hl("transitionend"),
  Mu = new Map(),
  Ts =
    "abort auxClick cancel canPlay canPlayThrough click close contextMenu copy cut drag dragEnd dragEnter dragExit dragLeave dragOver dragStart drop durationChange emptied encrypted ended error gotPointerCapture input invalid keyDown keyPress keyUp load loadedData loadedMetadata loadStart lostPointerCapture mouseDown mouseMove mouseOut mouseOver mouseUp paste pause play playing pointerCancel pointerDown pointerMove pointerOut pointerOver pointerUp progress rateChange reset resize seeked seeking stalled submit suspend timeUpdate touchCancel touchEnd touchStart volumeChange scroll toggle touchMove waiting wheel".split(
      " "
    );
function vt(e, t) {
  Mu.set(e, t), Ot(t, [e]);
}
for (var Ql = 0; Ql < Ts.length; Ql++) {
  var Gl = Ts[Ql],
    V0 = Gl.toLowerCase(),
    H0 = Gl[0].toUpperCase() + Gl.slice(1);
  vt(V0, "on" + H0);
}
vt(_u, "onAnimationEnd");
vt(Nu, "onAnimationIteration");
vt(Pu, "onAnimationStart");
vt("dblclick", "onDoubleClick");
vt("focusin", "onFocus");
vt("focusout", "onBlur");
vt(zu, "onTransitionEnd");
nn("onMouseEnter", ["mouseout", "mouseover"]);
nn("onMouseLeave", ["mouseout", "mouseover"]);
nn("onPointerEnter", ["pointerout", "pointerover"]);
nn("onPointerLeave", ["pointerout", "pointerover"]);
Ot(
  "onChange",
  "change click focusin focusout input keydown keyup selectionchange".split(" ")
);
Ot(
  "onSelect",
  "focusout contextmenu dragend focusin keydown keyup mousedown mouseup selectionchange".split(
    " "
  )
);
Ot("onBeforeInput", ["compositionend", "keypress", "textInput", "paste"]);
Ot(
  "onCompositionEnd",
  "compositionend focusout keydown keypress keyup mousedown".split(" ")
);
Ot(
  "onCompositionStart",
  "compositionstart focusout keydown keypress keyup mousedown".split(" ")
);
Ot(
  "onCompositionUpdate",
  "compositionupdate focusout keydown keypress keyup mousedown".split(" ")
);
var Nn =
    "abort canplay canplaythrough durationchange emptied encrypted ended error loadeddata loadedmetadata loadstart pause play playing progress ratechange resize seeked seeking stalled suspend timeupdate volumechange waiting".split(
      " "
    ),
  Z0 = new Set("cancel close invalid load scroll toggle".split(" ").concat(Nn));
function Rs(e, t, n) {
  var r = e.type || "unknown-event";
  (e.currentTarget = n), V3(r, t, void 0, e), (e.currentTarget = null);
}
function Tu(e, t) {
  t = (t & 4) !== 0;
  for (var n = 0; n < e.length; n++) {
    var r = e[n],
      l = r.event;
    r = r.listeners;
    e: {
      var i = void 0;
      if (t)
        for (var o = r.length - 1; 0 <= o; o--) {
          var a = r[o],
            u = a.instance,
            f = a.currentTarget;
          if (((a = a.listener), u !== i && l.isPropagationStopped())) break e;
          Rs(l, a, f), (i = u);
        }
      else
        for (o = 0; o < r.length; o++) {
          if (
            ((a = r[o]),
            (u = a.instance),
            (f = a.currentTarget),
            (a = a.listener),
            u !== i && l.isPropagationStopped())
          )
            break e;
          Rs(l, a, f), (i = u);
        }
    }
  }
  if (Hr) throw ((e = ji), (Hr = !1), (ji = null), e);
}
function F(e, t) {
  var n = t[Di];
  n === void 0 && (n = t[Di] = new Set());
  var r = e + "__bubble";
  n.has(r) || (Ru(t, e, 2, !1), n.add(r));
}
function Kl(e, t, n) {
  var r = 0;
  t && (r |= 4), Ru(n, e, r, t);
}
var wr = "_reactListening" + Math.random().toString(36).slice(2);
function Kn(e) {
  if (!e[wr]) {
    (e[wr] = !0),
      $a.forEach(function (n) {
        n !== "selectionchange" && (Z0.has(n) || Kl(n, !1, e), Kl(n, !0, e));
      });
    var t = e.nodeType === 9 ? e : e.ownerDocument;
    t === null || t[wr] || ((t[wr] = !0), Kl("selectionchange", !1, t));
  }
}
function Ru(e, t, n, r) {
  switch (vu(t)) {
    case 1:
      var l = l0;
      break;
    case 4:
      l = i0;
      break;
    default:
      l = yo;
  }
  (n = l.bind(null, t, n, e)),
    (l = void 0),
    !Ei ||
      (t !== "touchstart" && t !== "touchmove" && t !== "wheel") ||
      (l = !0),
    r
      ? l !== void 0
        ? e.addEventListener(t, n, { capture: !0, passive: l })
        : e.addEventListener(t, n, !0)
      : l !== void 0
      ? e.addEventListener(t, n, { passive: l })
      : e.addEventListener(t, n, !1);
}
function Yl(e, t, n, r, l) {
  var i = r;
  if (!(t & 1) && !(t & 2) && r !== null)
    e: for (;;) {
      if (r === null) return;
      var o = r.tag;
      if (o === 3 || o === 4) {
        var a = r.stateNode.containerInfo;
        if (a === l || (a.nodeType === 8 && a.parentNode === l)) break;
        if (o === 4)
          for (o = r.return; o !== null; ) {
            var u = o.tag;
            if (
              (u === 3 || u === 4) &&
              ((u = o.stateNode.containerInfo),
              u === l || (u.nodeType === 8 && u.parentNode === l))
            )
              return;
            o = o.return;
          }
        for (; a !== null; ) {
          if (((o = jt(a)), o === null)) return;
          if (((u = o.tag), u === 5 || u === 6)) {
            r = i = o;
            continue e;
          }
          a = a.parentNode;
        }
      }
      r = r.return;
    }
  nu(function () {
    var f = i,
      c = ho(n),
      h = [];
    e: {
      var v = Mu.get(e);
      if (v !== void 0) {
        var g = wo,
          x = e;
        switch (e) {
          case "keypress":
            if (Rr(n) === 0) break e;
          case "keydown":
          case "keyup":
            g = C0;
            break;
          case "focusin":
            (x = "focus"), (g = Vl);
            break;
          case "focusout":
            (x = "blur"), (g = Vl);
            break;
          case "beforeblur":
          case "afterblur":
            g = Vl;
            break;
          case "click":
            if (n.button === 2) break e;
          case "auxclick":
          case "dblclick":
          case "mousedown":
          case "mousemove":
          case "mouseup":
          case "mouseout":
          case "mouseover":
          case "contextmenu":
            g = ws;
            break;
          case "drag":
          case "dragend":
          case "dragenter":
          case "dragexit":
          case "dragleave":
          case "dragover":
          case "dragstart":
          case "drop":
            g = a0;
            break;
          case "touchcancel":
          case "touchend":
          case "touchmove":
          case "touchstart":
            g = E0;
            break;
          case _u:
          case Nu:
          case Pu:
            g = f0;
            break;
          case zu:
            g = k0;
            break;
          case "scroll":
            g = o0;
            break;
          case "wheel":
            g = _0;
            break;
          case "copy":
          case "cut":
          case "paste":
            g = p0;
            break;
          case "gotpointercapture":
          case "lostpointercapture":
          case "pointercancel":
          case "pointerdown":
          case "pointermove":
          case "pointerout":
          case "pointerover":
          case "pointerup":
            g = Es;
        }
        var C = (t & 4) !== 0,
          j = !C && e === "scroll",
          p = C ? (v !== null ? v + "Capture" : null) : v;
        C = [];
        for (var d = f, m; d !== null; ) {
          m = d;
          var y = m.stateNode;
          if (
            (m.tag === 5 &&
              y !== null &&
              ((m = y),
              p !== null && ((y = Vn(d, p)), y != null && C.push(Yn(d, y, m)))),
            j)
          )
            break;
          d = d.return;
        }
        0 < C.length &&
          ((v = new g(v, x, null, n, c)), h.push({ event: v, listeners: C }));
      }
    }
    if (!(t & 7)) {
      e: {
        if (
          ((v = e === "mouseover" || e === "pointerover"),
          (g = e === "mouseout" || e === "pointerout"),
          v &&
            n !== wi &&
            (x = n.relatedTarget || n.fromElement) &&
            (jt(x) || x[Ke]))
        )
          break e;
        if (
          (g || v) &&
          ((v =
            c.window === c
              ? c
              : (v = c.ownerDocument)
              ? v.defaultView || v.parentWindow
              : window),
          g
            ? ((x = n.relatedTarget || n.toElement),
              (g = f),
              (x = x ? jt(x) : null),
              x !== null &&
                ((j = Ut(x)), x !== j || (x.tag !== 5 && x.tag !== 6)) &&
                (x = null))
            : ((g = null), (x = f)),
          g !== x)
        ) {
          if (
            ((C = ws),
            (y = "onMouseLeave"),
            (p = "onMouseEnter"),
            (d = "mouse"),
            (e === "pointerout" || e === "pointerover") &&
              ((C = Es),
              (y = "onPointerLeave"),
              (p = "onPointerEnter"),
              (d = "pointer")),
            (j = g == null ? v : Ht(g)),
            (m = x == null ? v : Ht(x)),
            (v = new C(y, d + "leave", g, n, c)),
            (v.target = j),
            (v.relatedTarget = m),
            (y = null),
            jt(c) === f &&
              ((C = new C(p, d + "enter", x, n, c)),
              (C.target = m),
              (C.relatedTarget = j),
              (y = C)),
            (j = y),
            g && x)
          )
            t: {
              for (C = g, p = x, d = 0, m = C; m; m = Ft(m)) d++;
              for (m = 0, y = p; y; y = Ft(y)) m++;
              for (; 0 < d - m; ) (C = Ft(C)), d--;
              for (; 0 < m - d; ) (p = Ft(p)), m--;
              for (; d--; ) {
                if (C === p || (p !== null && C === p.alternate)) break t;
                (C = Ft(C)), (p = Ft(p));
              }
              C = null;
            }
          else C = null;
          g !== null && Ds(h, v, g, C, !1),
            x !== null && j !== null && Ds(h, j, x, C, !0);
        }
      }
      e: {
        if (
          ((v = f ? Ht(f) : window),
          (g = v.nodeName && v.nodeName.toLowerCase()),
          g === "select" || (g === "input" && v.type === "file"))
        )
          var E = D0;
        else if (Ls(v))
          if (Su) E = B0;
          else {
            E = U0;
            var _ = O0;
          }
        else
          (g = v.nodeName) &&
            g.toLowerCase() === "input" &&
            (v.type === "checkbox" || v.type === "radio") &&
            (E = F0);
        if (E && (E = E(e, f))) {
          wu(h, E, n, c);
          break e;
        }
        _ && _(e, v, f),
          e === "focusout" &&
            (_ = v._wrapperState) &&
            _.controlled &&
            v.type === "number" &&
            vi(v, "number", v.value);
      }
      switch (((_ = f ? Ht(f) : window), e)) {
        case "focusin":
          (Ls(_) || _.contentEditable === "true") &&
            ((At = _), (Ni = f), (On = null));
          break;
        case "focusout":
          On = Ni = At = null;
          break;
        case "mousedown":
          Pi = !0;
          break;
        case "contextmenu":
        case "mouseup":
        case "dragend":
          (Pi = !1), Ms(h, n, c);
          break;
        case "selectionchange":
          if (A0) break;
        case "keydown":
        case "keyup":
          Ms(h, n, c);
      }
      var N;
      if (Eo)
        e: {
          switch (e) {
            case "compositionstart":
              var z = "onCompositionStart";
              break e;
            case "compositionend":
              z = "onCompositionEnd";
              break e;
            case "compositionupdate":
              z = "onCompositionUpdate";
              break e;
          }
          z = void 0;
        }
      else
        $t
          ? yu(e, n) && (z = "onCompositionEnd")
          : e === "keydown" && n.keyCode === 229 && (z = "onCompositionStart");
      z &&
        (xu &&
          n.locale !== "ko" &&
          ($t || z !== "onCompositionStart"
            ? z === "onCompositionEnd" && $t && (N = gu())
            : ((rt = c),
              (Co = "value" in rt ? rt.value : rt.textContent),
              ($t = !0))),
        (_ = Kr(f, z)),
        0 < _.length &&
          ((z = new Ss(z, e, null, n, c)),
          h.push({ event: z, listeners: _ }),
          N ? (z.data = N) : ((N = Cu(n)), N !== null && (z.data = N)))),
        (N = P0 ? z0(e, n) : M0(e, n)) &&
          ((f = Kr(f, "onBeforeInput")),
          0 < f.length &&
            ((c = new Ss("onBeforeInput", "beforeinput", null, n, c)),
            h.push({ event: c, listeners: f }),
            (c.data = N)));
    }
    Tu(h, t);
  });
}
function Yn(e, t, n) {
  return { instance: e, listener: t, currentTarget: n };
}
function Kr(e, t) {
  for (var n = t + "Capture", r = []; e !== null; ) {
    var l = e,
      i = l.stateNode;
    l.tag === 5 &&
      i !== null &&
      ((l = i),
      (i = Vn(e, n)),
      i != null && r.unshift(Yn(e, i, l)),
      (i = Vn(e, t)),
      i != null && r.push(Yn(e, i, l))),
      (e = e.return);
  }
  return r;
}
function Ft(e) {
  if (e === null) return null;
  do e = e.return;
  while (e && e.tag !== 5);
  return e || null;
}
function Ds(e, t, n, r, l) {
  for (var i = t._reactName, o = []; n !== null && n !== r; ) {
    var a = n,
      u = a.alternate,
      f = a.stateNode;
    if (u !== null && u === r) break;
    a.tag === 5 &&
      f !== null &&
      ((a = f),
      l
        ? ((u = Vn(n, i)), u != null && o.unshift(Yn(n, u, a)))
        : l || ((u = Vn(n, i)), u != null && o.push(Yn(n, u, a)))),
      (n = n.return);
  }
  o.length !== 0 && e.push({ event: t, listeners: o });
}
var W0 = /\r\n?/g,
  Q0 = /\u0000|\uFFFD/g;
function Os(e) {
  return (typeof e == "string" ? e : "" + e)
    .replace(
      W0,
      `
`
    )
    .replace(Q0, "");
}
function Sr(e, t, n) {
  if (((t = Os(t)), Os(e) !== t && n)) throw Error(w(425));
}
function Yr() {}
var zi = null,
  Mi = null;
function Ti(e, t) {
  return (
    e === "textarea" ||
    e === "noscript" ||
    typeof t.children == "string" ||
    typeof t.children == "number" ||
    (typeof t.dangerouslySetInnerHTML == "object" &&
      t.dangerouslySetInnerHTML !== null &&
      t.dangerouslySetInnerHTML.__html != null)
  );
}
var Ri = typeof setTimeout == "function" ? setTimeout : void 0,
  G0 = typeof clearTimeout == "function" ? clearTimeout : void 0,
  Us = typeof Promise == "function" ? Promise : void 0,
  K0 =
    typeof queueMicrotask == "function"
      ? queueMicrotask
      : typeof Us < "u"
      ? function (e) {
          return Us.resolve(null).then(e).catch(Y0);
        }
      : Ri;
function Y0(e) {
  setTimeout(function () {
    throw e;
  });
}
function Xl(e, t) {
  var n = t,
    r = 0;
  do {
    var l = n.nextSibling;
    if ((e.removeChild(n), l && l.nodeType === 8))
      if (((n = l.data), n === "/$")) {
        if (r === 0) {
          e.removeChild(l), Wn(t);
          return;
        }
        r--;
      } else (n !== "$" && n !== "$?" && n !== "$!") || r++;
    n = l;
  } while (n);
  Wn(t);
}
function ut(e) {
  for (; e != null; e = e.nextSibling) {
    var t = e.nodeType;
    if (t === 1 || t === 3) break;
    if (t === 8) {
      if (((t = e.data), t === "$" || t === "$!" || t === "$?")) break;
      if (t === "/$") return null;
    }
  }
  return e;
}
function Fs(e) {
  e = e.previousSibling;
  for (var t = 0; e; ) {
    if (e.nodeType === 8) {
      var n = e.data;
      if (n === "$" || n === "$!" || n === "$?") {
        if (t === 0) return e;
        t--;
      } else n === "/$" && t++;
    }
    e = e.previousSibling;
  }
  return null;
}
var pn = Math.random().toString(36).slice(2),
  Ie = "__reactFiber$" + pn,
  Xn = "__reactProps$" + pn,
  Ke = "__reactContainer$" + pn,
  Di = "__reactEvents$" + pn,
  X0 = "__reactListeners$" + pn,
  J0 = "__reactHandles$" + pn;
function jt(e) {
  var t = e[Ie];
  if (t) return t;
  for (var n = e.parentNode; n; ) {
    if ((t = n[Ke] || n[Ie])) {
      if (
        ((n = t.alternate),
        t.child !== null || (n !== null && n.child !== null))
      )
        for (e = Fs(e); e !== null; ) {
          if ((n = e[Ie])) return n;
          e = Fs(e);
        }
      return t;
    }
    (e = n), (n = e.parentNode);
  }
  return null;
}
function ar(e) {
  return (
    (e = e[Ie] || e[Ke]),
    !e || (e.tag !== 5 && e.tag !== 6 && e.tag !== 13 && e.tag !== 3) ? null : e
  );
}
function Ht(e) {
  if (e.tag === 5 || e.tag === 6) return e.stateNode;
  throw Error(w(33));
}
function vl(e) {
  return e[Xn] || null;
}
var Oi = [],
  Zt = -1;
function gt(e) {
  return { current: e };
}
function B(e) {
  0 > Zt || ((e.current = Oi[Zt]), (Oi[Zt] = null), Zt--);
}
function U(e, t) {
  Zt++, (Oi[Zt] = e.current), (e.current = t);
}
var ht = {},
  se = gt(ht),
  me = gt(!1),
  zt = ht;
function rn(e, t) {
  var n = e.type.contextTypes;
  if (!n) return ht;
  var r = e.stateNode;
  if (r && r.__reactInternalMemoizedUnmaskedChildContext === t)
    return r.__reactInternalMemoizedMaskedChildContext;
  var l = {},
    i;
  for (i in n) l[i] = t[i];
  return (
    r &&
      ((e = e.stateNode),
      (e.__reactInternalMemoizedUnmaskedChildContext = t),
      (e.__reactInternalMemoizedMaskedChildContext = l)),
    l
  );
}
function he(e) {
  return (e = e.childContextTypes), e != null;
}
function Xr() {
  B(me), B(se);
}
function Bs(e, t, n) {
  if (se.current !== ht) throw Error(w(168));
  U(se, t), U(me, n);
}
function Du(e, t, n) {
  var r = e.stateNode;
  if (((t = t.childContextTypes), typeof r.getChildContext != "function"))
    return n;
  r = r.getChildContext();
  for (var l in r) if (!(l in t)) throw Error(w(108, O3(e) || "Unknown", l));
  return H({}, n, r);
}
function Jr(e) {
  return (
    (e =
      ((e = e.stateNode) && e.__reactInternalMemoizedMergedChildContext) || ht),
    (zt = se.current),
    U(se, e),
    U(me, me.current),
    !0
  );
}
function Is(e, t, n) {
  var r = e.stateNode;
  if (!r) throw Error(w(169));
  n
    ? ((e = Du(e, t, zt)),
      (r.__reactInternalMemoizedMergedChildContext = e),
      B(me),
      B(se),
      U(se, e))
    : B(me),
    U(me, n);
}
var He = null,
  gl = !1,
  Jl = !1;
function Ou(e) {
  He === null ? (He = [e]) : He.push(e);
}
function q0(e) {
  (gl = !0), Ou(e);
}
function xt() {
  if (!Jl && He !== null) {
    Jl = !0;
    var e = 0,
      t = O;
    try {
      var n = He;
      for (O = 1; e < n.length; e++) {
        var r = n[e];
        do r = r(!0);
        while (r !== null);
      }
      (He = null), (gl = !1);
    } catch (l) {
      throw (He !== null && (He = He.slice(e + 1)), ou(vo, xt), l);
    } finally {
      (O = t), (Jl = !1);
    }
  }
  return null;
}
var Wt = [],
  Qt = 0,
  qr = null,
  br = 0,
  Ee = [],
  je = 0,
  Mt = null,
  Ze = 1,
  We = "";
function St(e, t) {
  (Wt[Qt++] = br), (Wt[Qt++] = qr), (qr = e), (br = t);
}
function Uu(e, t, n) {
  (Ee[je++] = Ze), (Ee[je++] = We), (Ee[je++] = Mt), (Mt = e);
  var r = Ze;
  e = We;
  var l = 32 - Re(r) - 1;
  (r &= ~(1 << l)), (n += 1);
  var i = 32 - Re(t) + l;
  if (30 < i) {
    var o = l - (l % 5);
    (i = (r & ((1 << o) - 1)).toString(32)),
      (r >>= o),
      (l -= o),
      (Ze = (1 << (32 - Re(t) + l)) | (n << l) | r),
      (We = i + e);
  } else (Ze = (1 << i) | (n << l) | r), (We = e);
}
function ko(e) {
  e.return !== null && (St(e, 1), Uu(e, 1, 0));
}
function Lo(e) {
  for (; e === qr; )
    (qr = Wt[--Qt]), (Wt[Qt] = null), (br = Wt[--Qt]), (Wt[Qt] = null);
  for (; e === Mt; )
    (Mt = Ee[--je]),
      (Ee[je] = null),
      (We = Ee[--je]),
      (Ee[je] = null),
      (Ze = Ee[--je]),
      (Ee[je] = null);
}
var ye = null,
  xe = null,
  $ = !1,
  Te = null;
function Fu(e, t) {
  var n = ke(5, null, null, 0);
  (n.elementType = "DELETED"),
    (n.stateNode = t),
    (n.return = e),
    (t = e.deletions),
    t === null ? ((e.deletions = [n]), (e.flags |= 16)) : t.push(n);
}
function $s(e, t) {
  switch (e.tag) {
    case 5:
      var n = e.type;
      return (
        (t =
          t.nodeType !== 1 || n.toLowerCase() !== t.nodeName.toLowerCase()
            ? null
            : t),
        t !== null
          ? ((e.stateNode = t), (ye = e), (xe = ut(t.firstChild)), !0)
          : !1
      );
    case 6:
      return (
        (t = e.pendingProps === "" || t.nodeType !== 3 ? null : t),
        t !== null ? ((e.stateNode = t), (ye = e), (xe = null), !0) : !1
      );
    case 13:
      return (
        (t = t.nodeType !== 8 ? null : t),
        t !== null
          ? ((n = Mt !== null ? { id: Ze, overflow: We } : null),
            (e.memoizedState = {
              dehydrated: t,
              treeContext: n,
              retryLane: 1073741824,
            }),
            (n = ke(18, null, null, 0)),
            (n.stateNode = t),
            (n.return = e),
            (e.child = n),
            (ye = e),
            (xe = null),
            !0)
          : !1
      );
    default:
      return !1;
  }
}
function Ui(e) {
  return (e.mode & 1) !== 0 && (e.flags & 128) === 0;
}
function Fi(e) {
  if ($) {
    var t = xe;
    if (t) {
      var n = t;
      if (!$s(e, t)) {
        if (Ui(e)) throw Error(w(418));
        t = ut(n.nextSibling);
        var r = ye;
        t && $s(e, t)
          ? Fu(r, n)
          : ((e.flags = (e.flags & -4097) | 2), ($ = !1), (ye = e));
      }
    } else {
      if (Ui(e)) throw Error(w(418));
      (e.flags = (e.flags & -4097) | 2), ($ = !1), (ye = e);
    }
  }
}
function As(e) {
  for (e = e.return; e !== null && e.tag !== 5 && e.tag !== 3 && e.tag !== 13; )
    e = e.return;
  ye = e;
}
function Er(e) {
  if (e !== ye) return !1;
  if (!$) return As(e), ($ = !0), !1;
  var t;
  if (
    ((t = e.tag !== 3) &&
      !(t = e.tag !== 5) &&
      ((t = e.type),
      (t = t !== "head" && t !== "body" && !Ti(e.type, e.memoizedProps))),
    t && (t = xe))
  ) {
    if (Ui(e)) throw (Bu(), Error(w(418)));
    for (; t; ) Fu(e, t), (t = ut(t.nextSibling));
  }
  if ((As(e), e.tag === 13)) {
    if (((e = e.memoizedState), (e = e !== null ? e.dehydrated : null), !e))
      throw Error(w(317));
    e: {
      for (e = e.nextSibling, t = 0; e; ) {
        if (e.nodeType === 8) {
          var n = e.data;
          if (n === "/$") {
            if (t === 0) {
              xe = ut(e.nextSibling);
              break e;
            }
            t--;
          } else (n !== "$" && n !== "$!" && n !== "$?") || t++;
        }
        e = e.nextSibling;
      }
      xe = null;
    }
  } else xe = ye ? ut(e.stateNode.nextSibling) : null;
  return !0;
}
function Bu() {
  for (var e = xe; e; ) e = ut(e.nextSibling);
}
function ln() {
  (xe = ye = null), ($ = !1);
}
function _o(e) {
  Te === null ? (Te = [e]) : Te.push(e);
}
var b0 = Je.ReactCurrentBatchConfig;
function ze(e, t) {
  if (e && e.defaultProps) {
    (t = H({}, t)), (e = e.defaultProps);
    for (var n in e) t[n] === void 0 && (t[n] = e[n]);
    return t;
  }
  return t;
}
var el = gt(null),
  tl = null,
  Gt = null,
  No = null;
function Po() {
  No = Gt = tl = null;
}
function zo(e) {
  var t = el.current;
  B(el), (e._currentValue = t);
}
function Bi(e, t, n) {
  for (; e !== null; ) {
    var r = e.alternate;
    if (
      ((e.childLanes & t) !== t
        ? ((e.childLanes |= t), r !== null && (r.childLanes |= t))
        : r !== null && (r.childLanes & t) !== t && (r.childLanes |= t),
      e === n)
    )
      break;
    e = e.return;
  }
}
function en(e, t) {
  (tl = e),
    (No = Gt = null),
    (e = e.dependencies),
    e !== null &&
      e.firstContext !== null &&
      (e.lanes & t && (pe = !0), (e.firstContext = null));
}
function _e(e) {
  var t = e._currentValue;
  if (No !== e)
    if (((e = { context: e, memoizedValue: t, next: null }), Gt === null)) {
      if (tl === null) throw Error(w(308));
      (Gt = e), (tl.dependencies = { lanes: 0, firstContext: e });
    } else Gt = Gt.next = e;
  return t;
}
var kt = null;
function Mo(e) {
  kt === null ? (kt = [e]) : kt.push(e);
}
function Iu(e, t, n, r) {
  var l = t.interleaved;
  return (
    l === null ? ((n.next = n), Mo(t)) : ((n.next = l.next), (l.next = n)),
    (t.interleaved = n),
    Ye(e, r)
  );
}
function Ye(e, t) {
  e.lanes |= t;
  var n = e.alternate;
  for (n !== null && (n.lanes |= t), n = e, e = e.return; e !== null; )
    (e.childLanes |= t),
      (n = e.alternate),
      n !== null && (n.childLanes |= t),
      (n = e),
      (e = e.return);
  return n.tag === 3 ? n.stateNode : null;
}
var et = !1;
function To(e) {
  e.updateQueue = {
    baseState: e.memoizedState,
    firstBaseUpdate: null,
    lastBaseUpdate: null,
    shared: { pending: null, interleaved: null, lanes: 0 },
    effects: null,
  };
}
function $u(e, t) {
  (e = e.updateQueue),
    t.updateQueue === e &&
      (t.updateQueue = {
        baseState: e.baseState,
        firstBaseUpdate: e.firstBaseUpdate,
        lastBaseUpdate: e.lastBaseUpdate,
        shared: e.shared,
        effects: e.effects,
      });
}
function Qe(e, t) {
  return {
    eventTime: e,
    lane: t,
    tag: 0,
    payload: null,
    callback: null,
    next: null,
  };
}
function ct(e, t, n) {
  var r = e.updateQueue;
  if (r === null) return null;
  if (((r = r.shared), D & 2)) {
    var l = r.pending;
    return (
      l === null ? (t.next = t) : ((t.next = l.next), (l.next = t)),
      (r.pending = t),
      Ye(e, n)
    );
  }
  return (
    (l = r.interleaved),
    l === null ? ((t.next = t), Mo(r)) : ((t.next = l.next), (l.next = t)),
    (r.interleaved = t),
    Ye(e, n)
  );
}
function Dr(e, t, n) {
  if (
    ((t = t.updateQueue), t !== null && ((t = t.shared), (n & 4194240) !== 0))
  ) {
    var r = t.lanes;
    (r &= e.pendingLanes), (n |= r), (t.lanes = n), go(e, n);
  }
}
function Vs(e, t) {
  var n = e.updateQueue,
    r = e.alternate;
  if (r !== null && ((r = r.updateQueue), n === r)) {
    var l = null,
      i = null;
    if (((n = n.firstBaseUpdate), n !== null)) {
      do {
        var o = {
          eventTime: n.eventTime,
          lane: n.lane,
          tag: n.tag,
          payload: n.payload,
          callback: n.callback,
          next: null,
        };
        i === null ? (l = i = o) : (i = i.next = o), (n = n.next);
      } while (n !== null);
      i === null ? (l = i = t) : (i = i.next = t);
    } else l = i = t;
    (n = {
      baseState: r.baseState,
      firstBaseUpdate: l,
      lastBaseUpdate: i,
      shared: r.shared,
      effects: r.effects,
    }),
      (e.updateQueue = n);
    return;
  }
  (e = n.lastBaseUpdate),
    e === null ? (n.firstBaseUpdate = t) : (e.next = t),
    (n.lastBaseUpdate = t);
}
function nl(e, t, n, r) {
  var l = e.updateQueue;
  et = !1;
  var i = l.firstBaseUpdate,
    o = l.lastBaseUpdate,
    a = l.shared.pending;
  if (a !== null) {
    l.shared.pending = null;
    var u = a,
      f = u.next;
    (u.next = null), o === null ? (i = f) : (o.next = f), (o = u);
    var c = e.alternate;
    c !== null &&
      ((c = c.updateQueue),
      (a = c.lastBaseUpdate),
      a !== o &&
        (a === null ? (c.firstBaseUpdate = f) : (a.next = f),
        (c.lastBaseUpdate = u)));
  }
  if (i !== null) {
    var h = l.baseState;
    (o = 0), (c = f = u = null), (a = i);
    do {
      var v = a.lane,
        g = a.eventTime;
      if ((r & v) === v) {
        c !== null &&
          (c = c.next =
            {
              eventTime: g,
              lane: 0,
              tag: a.tag,
              payload: a.payload,
              callback: a.callback,
              next: null,
            });
        e: {
          var x = e,
            C = a;
          switch (((v = t), (g = n), C.tag)) {
            case 1:
              if (((x = C.payload), typeof x == "function")) {
                h = x.call(g, h, v);
                break e;
              }
              h = x;
              break e;
            case 3:
              x.flags = (x.flags & -65537) | 128;
            case 0:
              if (
                ((x = C.payload),
                (v = typeof x == "function" ? x.call(g, h, v) : x),
                v == null)
              )
                break e;
              h = H({}, h, v);
              break e;
            case 2:
              et = !0;
          }
        }
        a.callback !== null &&
          a.lane !== 0 &&
          ((e.flags |= 64),
          (v = l.effects),
          v === null ? (l.effects = [a]) : v.push(a));
      } else
        (g = {
          eventTime: g,
          lane: v,
          tag: a.tag,
          payload: a.payload,
          callback: a.callback,
          next: null,
        }),
          c === null ? ((f = c = g), (u = h)) : (c = c.next = g),
          (o |= v);
      if (((a = a.next), a === null)) {
        if (((a = l.shared.pending), a === null)) break;
        (v = a),
          (a = v.next),
          (v.next = null),
          (l.lastBaseUpdate = v),
          (l.shared.pending = null);
      }
    } while (!0);
    if (
      (c === null && (u = h),
      (l.baseState = u),
      (l.firstBaseUpdate = f),
      (l.lastBaseUpdate = c),
      (t = l.shared.interleaved),
      t !== null)
    ) {
      l = t;
      do (o |= l.lane), (l = l.next);
      while (l !== t);
    } else i === null && (l.shared.lanes = 0);
    (Rt |= o), (e.lanes = o), (e.memoizedState = h);
  }
}
function Hs(e, t, n) {
  if (((e = t.effects), (t.effects = null), e !== null))
    for (t = 0; t < e.length; t++) {
      var r = e[t],
        l = r.callback;
      if (l !== null) {
        if (((r.callback = null), (r = n), typeof l != "function"))
          throw Error(w(191, l));
        l.call(r);
      }
    }
}
var Au = new Ia.Component().refs;
function Ii(e, t, n, r) {
  (t = e.memoizedState),
    (n = n(r, t)),
    (n = n == null ? t : H({}, t, n)),
    (e.memoizedState = n),
    e.lanes === 0 && (e.updateQueue.baseState = n);
}
var xl = {
  isMounted: function (e) {
    return (e = e._reactInternals) ? Ut(e) === e : !1;
  },
  enqueueSetState: function (e, t, n) {
    e = e._reactInternals;
    var r = ue(),
      l = dt(e),
      i = Qe(r, l);
    (i.payload = t),
      n != null && (i.callback = n),
      (t = ct(e, i, l)),
      t !== null && (De(t, e, l, r), Dr(t, e, l));
  },
  enqueueReplaceState: function (e, t, n) {
    e = e._reactInternals;
    var r = ue(),
      l = dt(e),
      i = Qe(r, l);
    (i.tag = 1),
      (i.payload = t),
      n != null && (i.callback = n),
      (t = ct(e, i, l)),
      t !== null && (De(t, e, l, r), Dr(t, e, l));
  },
  enqueueForceUpdate: function (e, t) {
    e = e._reactInternals;
    var n = ue(),
      r = dt(e),
      l = Qe(n, r);
    (l.tag = 2),
      t != null && (l.callback = t),
      (t = ct(e, l, r)),
      t !== null && (De(t, e, r, n), Dr(t, e, r));
  },
};
function Zs(e, t, n, r, l, i, o) {
  return (
    (e = e.stateNode),
    typeof e.shouldComponentUpdate == "function"
      ? e.shouldComponentUpdate(r, i, o)
      : t.prototype && t.prototype.isPureReactComponent
      ? !Gn(n, r) || !Gn(l, i)
      : !0
  );
}
function Vu(e, t, n) {
  var r = !1,
    l = ht,
    i = t.contextType;
  return (
    typeof i == "object" && i !== null
      ? (i = _e(i))
      : ((l = he(t) ? zt : se.current),
        (r = t.contextTypes),
        (i = (r = r != null) ? rn(e, l) : ht)),
    (t = new t(n, i)),
    (e.memoizedState = t.state !== null && t.state !== void 0 ? t.state : null),
    (t.updater = xl),
    (e.stateNode = t),
    (t._reactInternals = e),
    r &&
      ((e = e.stateNode),
      (e.__reactInternalMemoizedUnmaskedChildContext = l),
      (e.__reactInternalMemoizedMaskedChildContext = i)),
    t
  );
}
function Ws(e, t, n, r) {
  (e = t.state),
    typeof t.componentWillReceiveProps == "function" &&
      t.componentWillReceiveProps(n, r),
    typeof t.UNSAFE_componentWillReceiveProps == "function" &&
      t.UNSAFE_componentWillReceiveProps(n, r),
    t.state !== e && xl.enqueueReplaceState(t, t.state, null);
}
function $i(e, t, n, r) {
  var l = e.stateNode;
  (l.props = n), (l.state = e.memoizedState), (l.refs = Au), To(e);
  var i = t.contextType;
  typeof i == "object" && i !== null
    ? (l.context = _e(i))
    : ((i = he(t) ? zt : se.current), (l.context = rn(e, i))),
    (l.state = e.memoizedState),
    (i = t.getDerivedStateFromProps),
    typeof i == "function" && (Ii(e, t, i, n), (l.state = e.memoizedState)),
    typeof t.getDerivedStateFromProps == "function" ||
      typeof l.getSnapshotBeforeUpdate == "function" ||
      (typeof l.UNSAFE_componentWillMount != "function" &&
        typeof l.componentWillMount != "function") ||
      ((t = l.state),
      typeof l.componentWillMount == "function" && l.componentWillMount(),
      typeof l.UNSAFE_componentWillMount == "function" &&
        l.UNSAFE_componentWillMount(),
      t !== l.state && xl.enqueueReplaceState(l, l.state, null),
      nl(e, n, l, r),
      (l.state = e.memoizedState)),
    typeof l.componentDidMount == "function" && (e.flags |= 4194308);
}
function Sn(e, t, n) {
  if (
    ((e = n.ref), e !== null && typeof e != "function" && typeof e != "object")
  ) {
    if (n._owner) {
      if (((n = n._owner), n)) {
        if (n.tag !== 1) throw Error(w(309));
        var r = n.stateNode;
      }
      if (!r) throw Error(w(147, e));
      var l = r,
        i = "" + e;
      return t !== null &&
        t.ref !== null &&
        typeof t.ref == "function" &&
        t.ref._stringRef === i
        ? t.ref
        : ((t = function (o) {
            var a = l.refs;
            a === Au && (a = l.refs = {}),
              o === null ? delete a[i] : (a[i] = o);
          }),
          (t._stringRef = i),
          t);
    }
    if (typeof e != "string") throw Error(w(284));
    if (!n._owner) throw Error(w(290, e));
  }
  return e;
}
function jr(e, t) {
  throw (
    ((e = Object.prototype.toString.call(t)),
    Error(
      w(
        31,
        e === "[object Object]"
          ? "object with keys {" + Object.keys(t).join(", ") + "}"
          : e
      )
    ))
  );
}
function Qs(e) {
  var t = e._init;
  return t(e._payload);
}
function Hu(e) {
  function t(p, d) {
    if (e) {
      var m = p.deletions;
      m === null ? ((p.deletions = [d]), (p.flags |= 16)) : m.push(d);
    }
  }
  function n(p, d) {
    if (!e) return null;
    for (; d !== null; ) t(p, d), (d = d.sibling);
    return null;
  }
  function r(p, d) {
    for (p = new Map(); d !== null; )
      d.key !== null ? p.set(d.key, d) : p.set(d.index, d), (d = d.sibling);
    return p;
  }
  function l(p, d) {
    return (p = pt(p, d)), (p.index = 0), (p.sibling = null), p;
  }
  function i(p, d, m) {
    return (
      (p.index = m),
      e
        ? ((m = p.alternate),
          m !== null
            ? ((m = m.index), m < d ? ((p.flags |= 2), d) : m)
            : ((p.flags |= 2), d))
        : ((p.flags |= 1048576), d)
    );
  }
  function o(p) {
    return e && p.alternate === null && (p.flags |= 2), p;
  }
  function a(p, d, m, y) {
    return d === null || d.tag !== 6
      ? ((d = li(m, p.mode, y)), (d.return = p), d)
      : ((d = l(d, m)), (d.return = p), d);
  }
  function u(p, d, m, y) {
    var E = m.type;
    return E === It
      ? c(p, d, m.props.children, y, m.key)
      : d !== null &&
        (d.elementType === E ||
          (typeof E == "object" &&
            E !== null &&
            E.$$typeof === be &&
            Qs(E) === d.type))
      ? ((y = l(d, m.props)), (y.ref = Sn(p, d, m)), (y.return = p), y)
      : ((y = $r(m.type, m.key, m.props, null, p.mode, y)),
        (y.ref = Sn(p, d, m)),
        (y.return = p),
        y);
  }
  function f(p, d, m, y) {
    return d === null ||
      d.tag !== 4 ||
      d.stateNode.containerInfo !== m.containerInfo ||
      d.stateNode.implementation !== m.implementation
      ? ((d = ii(m, p.mode, y)), (d.return = p), d)
      : ((d = l(d, m.children || [])), (d.return = p), d);
  }
  function c(p, d, m, y, E) {
    return d === null || d.tag !== 7
      ? ((d = Nt(m, p.mode, y, E)), (d.return = p), d)
      : ((d = l(d, m)), (d.return = p), d);
  }
  function h(p, d, m) {
    if ((typeof d == "string" && d !== "") || typeof d == "number")
      return (d = li("" + d, p.mode, m)), (d.return = p), d;
    if (typeof d == "object" && d !== null) {
      switch (d.$$typeof) {
        case pr:
          return (
            (m = $r(d.type, d.key, d.props, null, p.mode, m)),
            (m.ref = Sn(p, null, d)),
            (m.return = p),
            m
          );
        case Bt:
          return (d = ii(d, p.mode, m)), (d.return = p), d;
        case be:
          var y = d._init;
          return h(p, y(d._payload), m);
      }
      if (Ln(d) || gn(d))
        return (d = Nt(d, p.mode, m, null)), (d.return = p), d;
      jr(p, d);
    }
    return null;
  }
  function v(p, d, m, y) {
    var E = d !== null ? d.key : null;
    if ((typeof m == "string" && m !== "") || typeof m == "number")
      return E !== null ? null : a(p, d, "" + m, y);
    if (typeof m == "object" && m !== null) {
      switch (m.$$typeof) {
        case pr:
          return m.key === E ? u(p, d, m, y) : null;
        case Bt:
          return m.key === E ? f(p, d, m, y) : null;
        case be:
          return (E = m._init), v(p, d, E(m._payload), y);
      }
      if (Ln(m) || gn(m)) return E !== null ? null : c(p, d, m, y, null);
      jr(p, m);
    }
    return null;
  }
  function g(p, d, m, y, E) {
    if ((typeof y == "string" && y !== "") || typeof y == "number")
      return (p = p.get(m) || null), a(d, p, "" + y, E);
    if (typeof y == "object" && y !== null) {
      switch (y.$$typeof) {
        case pr:
          return (p = p.get(y.key === null ? m : y.key) || null), u(d, p, y, E);
        case Bt:
          return (p = p.get(y.key === null ? m : y.key) || null), f(d, p, y, E);
        case be:
          var _ = y._init;
          return g(p, d, m, _(y._payload), E);
      }
      if (Ln(y) || gn(y)) return (p = p.get(m) || null), c(d, p, y, E, null);
      jr(d, y);
    }
    return null;
  }
  function x(p, d, m, y) {
    for (
      var E = null, _ = null, N = d, z = (d = 0), I = null;
      N !== null && z < m.length;
      z++
    ) {
      N.index > z ? ((I = N), (N = null)) : (I = N.sibling);
      var P = v(p, N, m[z], y);
      if (P === null) {
        N === null && (N = I);
        break;
      }
      e && N && P.alternate === null && t(p, N),
        (d = i(P, d, z)),
        _ === null ? (E = P) : (_.sibling = P),
        (_ = P),
        (N = I);
    }
    if (z === m.length) return n(p, N), $ && St(p, z), E;
    if (N === null) {
      for (; z < m.length; z++)
        (N = h(p, m[z], y)),
          N !== null &&
            ((d = i(N, d, z)), _ === null ? (E = N) : (_.sibling = N), (_ = N));
      return $ && St(p, z), E;
    }
    for (N = r(p, N); z < m.length; z++)
      (I = g(N, p, z, m[z], y)),
        I !== null &&
          (e && I.alternate !== null && N.delete(I.key === null ? z : I.key),
          (d = i(I, d, z)),
          _ === null ? (E = I) : (_.sibling = I),
          (_ = I));
    return (
      e &&
        N.forEach(function (J) {
          return t(p, J);
        }),
      $ && St(p, z),
      E
    );
  }
  function C(p, d, m, y) {
    var E = gn(m);
    if (typeof E != "function") throw Error(w(150));
    if (((m = E.call(m)), m == null)) throw Error(w(151));
    for (
      var _ = (E = null), N = d, z = (d = 0), I = null, P = m.next();
      N !== null && !P.done;
      z++, P = m.next()
    ) {
      N.index > z ? ((I = N), (N = null)) : (I = N.sibling);
      var J = v(p, N, P.value, y);
      if (J === null) {
        N === null && (N = I);
        break;
      }
      e && N && J.alternate === null && t(p, N),
        (d = i(J, d, z)),
        _ === null ? (E = J) : (_.sibling = J),
        (_ = J),
        (N = I);
    }
    if (P.done) return n(p, N), $ && St(p, z), E;
    if (N === null) {
      for (; !P.done; z++, P = m.next())
        (P = h(p, P.value, y)),
          P !== null &&
            ((d = i(P, d, z)), _ === null ? (E = P) : (_.sibling = P), (_ = P));
      return $ && St(p, z), E;
    }
    for (N = r(p, N); !P.done; z++, P = m.next())
      (P = g(N, p, z, P.value, y)),
        P !== null &&
          (e && P.alternate !== null && N.delete(P.key === null ? z : P.key),
          (d = i(P, d, z)),
          _ === null ? (E = P) : (_.sibling = P),
          (_ = P));
    return (
      e &&
        N.forEach(function (yt) {
          return t(p, yt);
        }),
      $ && St(p, z),
      E
    );
  }
  function j(p, d, m, y) {
    if (
      (typeof m == "object" &&
        m !== null &&
        m.type === It &&
        m.key === null &&
        (m = m.props.children),
      typeof m == "object" && m !== null)
    ) {
      switch (m.$$typeof) {
        case pr:
          e: {
            for (var E = m.key, _ = d; _ !== null; ) {
              if (_.key === E) {
                if (((E = m.type), E === It)) {
                  if (_.tag === 7) {
                    n(p, _.sibling),
                      (d = l(_, m.props.children)),
                      (d.return = p),
                      (p = d);
                    break e;
                  }
                } else if (
                  _.elementType === E ||
                  (typeof E == "object" &&
                    E !== null &&
                    E.$$typeof === be &&
                    Qs(E) === _.type)
                ) {
                  n(p, _.sibling),
                    (d = l(_, m.props)),
                    (d.ref = Sn(p, _, m)),
                    (d.return = p),
                    (p = d);
                  break e;
                }
                n(p, _);
                break;
              } else t(p, _);
              _ = _.sibling;
            }
            m.type === It
              ? ((d = Nt(m.props.children, p.mode, y, m.key)),
                (d.return = p),
                (p = d))
              : ((y = $r(m.type, m.key, m.props, null, p.mode, y)),
                (y.ref = Sn(p, d, m)),
                (y.return = p),
                (p = y));
          }
          return o(p);
        case Bt:
          e: {
            for (_ = m.key; d !== null; ) {
              if (d.key === _)
                if (
                  d.tag === 4 &&
                  d.stateNode.containerInfo === m.containerInfo &&
                  d.stateNode.implementation === m.implementation
                ) {
                  n(p, d.sibling),
                    (d = l(d, m.children || [])),
                    (d.return = p),
                    (p = d);
                  break e;
                } else {
                  n(p, d);
                  break;
                }
              else t(p, d);
              d = d.sibling;
            }
            (d = ii(m, p.mode, y)), (d.return = p), (p = d);
          }
          return o(p);
        case be:
          return (_ = m._init), j(p, d, _(m._payload), y);
      }
      if (Ln(m)) return x(p, d, m, y);
      if (gn(m)) return C(p, d, m, y);
      jr(p, m);
    }
    return (typeof m == "string" && m !== "") || typeof m == "number"
      ? ((m = "" + m),
        d !== null && d.tag === 6
          ? (n(p, d.sibling), (d = l(d, m)), (d.return = p), (p = d))
          : (n(p, d), (d = li(m, p.mode, y)), (d.return = p), (p = d)),
        o(p))
      : n(p, d);
  }
  return j;
}
var on = Hu(!0),
  Zu = Hu(!1),
  ur = {},
  Ae = gt(ur),
  Jn = gt(ur),
  qn = gt(ur);
function Lt(e) {
  if (e === ur) throw Error(w(174));
  return e;
}
function Ro(e, t) {
  switch ((U(qn, t), U(Jn, e), U(Ae, ur), (e = t.nodeType), e)) {
    case 9:
    case 11:
      t = (t = t.documentElement) ? t.namespaceURI : xi(null, "");
      break;
    default:
      (e = e === 8 ? t.parentNode : t),
        (t = e.namespaceURI || null),
        (e = e.tagName),
        (t = xi(t, e));
  }
  B(Ae), U(Ae, t);
}
function sn() {
  B(Ae), B(Jn), B(qn);
}
function Wu(e) {
  Lt(qn.current);
  var t = Lt(Ae.current),
    n = xi(t, e.type);
  t !== n && (U(Jn, e), U(Ae, n));
}
function Do(e) {
  Jn.current === e && (B(Ae), B(Jn));
}
var A = gt(0);
function rl(e) {
  for (var t = e; t !== null; ) {
    if (t.tag === 13) {
      var n = t.memoizedState;
      if (
        n !== null &&
        ((n = n.dehydrated), n === null || n.data === "$?" || n.data === "$!")
      )
        return t;
    } else if (t.tag === 19 && t.memoizedProps.revealOrder !== void 0) {
      if (t.flags & 128) return t;
    } else if (t.child !== null) {
      (t.child.return = t), (t = t.child);
      continue;
    }
    if (t === e) break;
    for (; t.sibling === null; ) {
      if (t.return === null || t.return === e) return null;
      t = t.return;
    }
    (t.sibling.return = t.return), (t = t.sibling);
  }
  return null;
}
var ql = [];
function Oo() {
  for (var e = 0; e < ql.length; e++)
    ql[e]._workInProgressVersionPrimary = null;
  ql.length = 0;
}
var Or = Je.ReactCurrentDispatcher,
  bl = Je.ReactCurrentBatchConfig,
  Tt = 0,
  V = null,
  K = null,
  b = null,
  ll = !1,
  Un = !1,
  bn = 0,
  ec = 0;
function le() {
  throw Error(w(321));
}
function Uo(e, t) {
  if (t === null) return !1;
  for (var n = 0; n < t.length && n < e.length; n++)
    if (!Ue(e[n], t[n])) return !1;
  return !0;
}
function Fo(e, t, n, r, l, i) {
  if (
    ((Tt = i),
    (V = t),
    (t.memoizedState = null),
    (t.updateQueue = null),
    (t.lanes = 0),
    (Or.current = e === null || e.memoizedState === null ? lc : ic),
    (e = n(r, l)),
    Un)
  ) {
    i = 0;
    do {
      if (((Un = !1), (bn = 0), 25 <= i)) throw Error(w(301));
      (i += 1),
        (b = K = null),
        (t.updateQueue = null),
        (Or.current = oc),
        (e = n(r, l));
    } while (Un);
  }
  if (
    ((Or.current = il),
    (t = K !== null && K.next !== null),
    (Tt = 0),
    (b = K = V = null),
    (ll = !1),
    t)
  )
    throw Error(w(300));
  return e;
}
function Bo() {
  var e = bn !== 0;
  return (bn = 0), e;
}
function Be() {
  var e = {
    memoizedState: null,
    baseState: null,
    baseQueue: null,
    queue: null,
    next: null,
  };
  return b === null ? (V.memoizedState = b = e) : (b = b.next = e), b;
}
function Ne() {
  if (K === null) {
    var e = V.alternate;
    e = e !== null ? e.memoizedState : null;
  } else e = K.next;
  var t = b === null ? V.memoizedState : b.next;
  if (t !== null) (b = t), (K = e);
  else {
    if (e === null) throw Error(w(310));
    (K = e),
      (e = {
        memoizedState: K.memoizedState,
        baseState: K.baseState,
        baseQueue: K.baseQueue,
        queue: K.queue,
        next: null,
      }),
      b === null ? (V.memoizedState = b = e) : (b = b.next = e);
  }
  return b;
}
function er(e, t) {
  return typeof t == "function" ? t(e) : t;
}
function ei(e) {
  var t = Ne(),
    n = t.queue;
  if (n === null) throw Error(w(311));
  n.lastRenderedReducer = e;
  var r = K,
    l = r.baseQueue,
    i = n.pending;
  if (i !== null) {
    if (l !== null) {
      var o = l.next;
      (l.next = i.next), (i.next = o);
    }
    (r.baseQueue = l = i), (n.pending = null);
  }
  if (l !== null) {
    (i = l.next), (r = r.baseState);
    var a = (o = null),
      u = null,
      f = i;
    do {
      var c = f.lane;
      if ((Tt & c) === c)
        u !== null &&
          (u = u.next =
            {
              lane: 0,
              action: f.action,
              hasEagerState: f.hasEagerState,
              eagerState: f.eagerState,
              next: null,
            }),
          (r = f.hasEagerState ? f.eagerState : e(r, f.action));
      else {
        var h = {
          lane: c,
          action: f.action,
          hasEagerState: f.hasEagerState,
          eagerState: f.eagerState,
          next: null,
        };
        u === null ? ((a = u = h), (o = r)) : (u = u.next = h),
          (V.lanes |= c),
          (Rt |= c);
      }
      f = f.next;
    } while (f !== null && f !== i);
    u === null ? (o = r) : (u.next = a),
      Ue(r, t.memoizedState) || (pe = !0),
      (t.memoizedState = r),
      (t.baseState = o),
      (t.baseQueue = u),
      (n.lastRenderedState = r);
  }
  if (((e = n.interleaved), e !== null)) {
    l = e;
    do (i = l.lane), (V.lanes |= i), (Rt |= i), (l = l.next);
    while (l !== e);
  } else l === null && (n.lanes = 0);
  return [t.memoizedState, n.dispatch];
}
function ti(e) {
  var t = Ne(),
    n = t.queue;
  if (n === null) throw Error(w(311));
  n.lastRenderedReducer = e;
  var r = n.dispatch,
    l = n.pending,
    i = t.memoizedState;
  if (l !== null) {
    n.pending = null;
    var o = (l = l.next);
    do (i = e(i, o.action)), (o = o.next);
    while (o !== l);
    Ue(i, t.memoizedState) || (pe = !0),
      (t.memoizedState = i),
      t.baseQueue === null && (t.baseState = i),
      (n.lastRenderedState = i);
  }
  return [i, r];
}
function Qu() {}
function Gu(e, t) {
  var n = V,
    r = Ne(),
    l = t(),
    i = !Ue(r.memoizedState, l);
  if (
    (i && ((r.memoizedState = l), (pe = !0)),
    (r = r.queue),
    Io(Xu.bind(null, n, r, e), [e]),
    r.getSnapshot !== t || i || (b !== null && b.memoizedState.tag & 1))
  ) {
    if (
      ((n.flags |= 2048),
      tr(9, Yu.bind(null, n, r, l, t), void 0, null),
      ee === null)
    )
      throw Error(w(349));
    Tt & 30 || Ku(n, t, l);
  }
  return l;
}
function Ku(e, t, n) {
  (e.flags |= 16384),
    (e = { getSnapshot: t, value: n }),
    (t = V.updateQueue),
    t === null
      ? ((t = { lastEffect: null, stores: null }),
        (V.updateQueue = t),
        (t.stores = [e]))
      : ((n = t.stores), n === null ? (t.stores = [e]) : n.push(e));
}
function Yu(e, t, n, r) {
  (t.value = n), (t.getSnapshot = r), Ju(t) && qu(e);
}
function Xu(e, t, n) {
  return n(function () {
    Ju(t) && qu(e);
  });
}
function Ju(e) {
  var t = e.getSnapshot;
  e = e.value;
  try {
    var n = t();
    return !Ue(e, n);
  } catch {
    return !0;
  }
}
function qu(e) {
  var t = Ye(e, 1);
  t !== null && De(t, e, 1, -1);
}
function Gs(e) {
  var t = Be();
  return (
    typeof e == "function" && (e = e()),
    (t.memoizedState = t.baseState = e),
    (e = {
      pending: null,
      interleaved: null,
      lanes: 0,
      dispatch: null,
      lastRenderedReducer: er,
      lastRenderedState: e,
    }),
    (t.queue = e),
    (e = e.dispatch = rc.bind(null, V, e)),
    [t.memoizedState, e]
  );
}
function tr(e, t, n, r) {
  return (
    (e = { tag: e, create: t, destroy: n, deps: r, next: null }),
    (t = V.updateQueue),
    t === null
      ? ((t = { lastEffect: null, stores: null }),
        (V.updateQueue = t),
        (t.lastEffect = e.next = e))
      : ((n = t.lastEffect),
        n === null
          ? (t.lastEffect = e.next = e)
          : ((r = n.next), (n.next = e), (e.next = r), (t.lastEffect = e))),
    e
  );
}
function bu() {
  return Ne().memoizedState;
}
function Ur(e, t, n, r) {
  var l = Be();
  (V.flags |= e),
    (l.memoizedState = tr(1 | t, n, void 0, r === void 0 ? null : r));
}
function yl(e, t, n, r) {
  var l = Ne();
  r = r === void 0 ? null : r;
  var i = void 0;
  if (K !== null) {
    var o = K.memoizedState;
    if (((i = o.destroy), r !== null && Uo(r, o.deps))) {
      l.memoizedState = tr(t, n, i, r);
      return;
    }
  }
  (V.flags |= e), (l.memoizedState = tr(1 | t, n, i, r));
}
function Ks(e, t) {
  return Ur(8390656, 8, e, t);
}
function Io(e, t) {
  return yl(2048, 8, e, t);
}
function e1(e, t) {
  return yl(4, 2, e, t);
}
function t1(e, t) {
  return yl(4, 4, e, t);
}
function n1(e, t) {
  if (typeof t == "function")
    return (
      (e = e()),
      t(e),
      function () {
        t(null);
      }
    );
  if (t != null)
    return (
      (e = e()),
      (t.current = e),
      function () {
        t.current = null;
      }
    );
}
function r1(e, t, n) {
  return (
    (n = n != null ? n.concat([e]) : null), yl(4, 4, n1.bind(null, t, e), n)
  );
}
function $o() {}
function l1(e, t) {
  var n = Ne();
  t = t === void 0 ? null : t;
  var r = n.memoizedState;
  return r !== null && t !== null && Uo(t, r[1])
    ? r[0]
    : ((n.memoizedState = [e, t]), e);
}
function i1(e, t) {
  var n = Ne();
  t = t === void 0 ? null : t;
  var r = n.memoizedState;
  return r !== null && t !== null && Uo(t, r[1])
    ? r[0]
    : ((e = e()), (n.memoizedState = [e, t]), e);
}
function o1(e, t, n) {
  return Tt & 21
    ? (Ue(n, t) || ((n = uu()), (V.lanes |= n), (Rt |= n), (e.baseState = !0)),
      t)
    : (e.baseState && ((e.baseState = !1), (pe = !0)), (e.memoizedState = n));
}
function tc(e, t) {
  var n = O;
  (O = n !== 0 && 4 > n ? n : 4), e(!0);
  var r = bl.transition;
  bl.transition = {};
  try {
    e(!1), t();
  } finally {
    (O = n), (bl.transition = r);
  }
}
function s1() {
  return Ne().memoizedState;
}
function nc(e, t, n) {
  var r = dt(e);
  if (
    ((n = {
      lane: r,
      action: n,
      hasEagerState: !1,
      eagerState: null,
      next: null,
    }),
    a1(e))
  )
    u1(t, n);
  else if (((n = Iu(e, t, n, r)), n !== null)) {
    var l = ue();
    De(n, e, r, l), c1(n, t, r);
  }
}
function rc(e, t, n) {
  var r = dt(e),
    l = { lane: r, action: n, hasEagerState: !1, eagerState: null, next: null };
  if (a1(e)) u1(t, l);
  else {
    var i = e.alternate;
    if (
      e.lanes === 0 &&
      (i === null || i.lanes === 0) &&
      ((i = t.lastRenderedReducer), i !== null)
    )
      try {
        var o = t.lastRenderedState,
          a = i(o, n);
        if (((l.hasEagerState = !0), (l.eagerState = a), Ue(a, o))) {
          var u = t.interleaved;
          u === null
            ? ((l.next = l), Mo(t))
            : ((l.next = u.next), (u.next = l)),
            (t.interleaved = l);
          return;
        }
      } catch {
      } finally {
      }
    (n = Iu(e, t, l, r)),
      n !== null && ((l = ue()), De(n, e, r, l), c1(n, t, r));
  }
}
function a1(e) {
  var t = e.alternate;
  return e === V || (t !== null && t === V);
}
function u1(e, t) {
  Un = ll = !0;
  var n = e.pending;
  n === null ? (t.next = t) : ((t.next = n.next), (n.next = t)),
    (e.pending = t);
}
function c1(e, t, n) {
  if (n & 4194240) {
    var r = t.lanes;
    (r &= e.pendingLanes), (n |= r), (t.lanes = n), go(e, n);
  }
}
var il = {
    readContext: _e,
    useCallback: le,
    useContext: le,
    useEffect: le,
    useImperativeHandle: le,
    useInsertionEffect: le,
    useLayoutEffect: le,
    useMemo: le,
    useReducer: le,
    useRef: le,
    useState: le,
    useDebugValue: le,
    useDeferredValue: le,
    useTransition: le,
    useMutableSource: le,
    useSyncExternalStore: le,
    useId: le,
    unstable_isNewReconciler: !1,
  },
  lc = {
    readContext: _e,
    useCallback: function (e, t) {
      return (Be().memoizedState = [e, t === void 0 ? null : t]), e;
    },
    useContext: _e,
    useEffect: Ks,
    useImperativeHandle: function (e, t, n) {
      return (
        (n = n != null ? n.concat([e]) : null),
        Ur(4194308, 4, n1.bind(null, t, e), n)
      );
    },
    useLayoutEffect: function (e, t) {
      return Ur(4194308, 4, e, t);
    },
    useInsertionEffect: function (e, t) {
      return Ur(4, 2, e, t);
    },
    useMemo: function (e, t) {
      var n = Be();
      return (
        (t = t === void 0 ? null : t), (e = e()), (n.memoizedState = [e, t]), e
      );
    },
    useReducer: function (e, t, n) {
      var r = Be();
      return (
        (t = n !== void 0 ? n(t) : t),
        (r.memoizedState = r.baseState = t),
        (e = {
          pending: null,
          interleaved: null,
          lanes: 0,
          dispatch: null,
          lastRenderedReducer: e,
          lastRenderedState: t,
        }),
        (r.queue = e),
        (e = e.dispatch = nc.bind(null, V, e)),
        [r.memoizedState, e]
      );
    },
    useRef: function (e) {
      var t = Be();
      return (e = { current: e }), (t.memoizedState = e);
    },
    useState: Gs,
    useDebugValue: $o,
    useDeferredValue: function (e) {
      return (Be().memoizedState = e);
    },
    useTransition: function () {
      var e = Gs(!1),
        t = e[0];
      return (e = tc.bind(null, e[1])), (Be().memoizedState = e), [t, e];
    },
    useMutableSource: function () {},
    useSyncExternalStore: function (e, t, n) {
      var r = V,
        l = Be();
      if ($) {
        if (n === void 0) throw Error(w(407));
        n = n();
      } else {
        if (((n = t()), ee === null)) throw Error(w(349));
        Tt & 30 || Ku(r, t, n);
      }
      l.memoizedState = n;
      var i = { value: n, getSnapshot: t };
      return (
        (l.queue = i),
        Ks(Xu.bind(null, r, i, e), [e]),
        (r.flags |= 2048),
        tr(9, Yu.bind(null, r, i, n, t), void 0, null),
        n
      );
    },
    useId: function () {
      var e = Be(),
        t = ee.identifierPrefix;
      if ($) {
        var n = We,
          r = Ze;
        (n = (r & ~(1 << (32 - Re(r) - 1))).toString(32) + n),
          (t = ":" + t + "R" + n),
          (n = bn++),
          0 < n && (t += "H" + n.toString(32)),
          (t += ":");
      } else (n = ec++), (t = ":" + t + "r" + n.toString(32) + ":");
      return (e.memoizedState = t);
    },
    unstable_isNewReconciler: !1,
  },
  ic = {
    readContext: _e,
    useCallback: l1,
    useContext: _e,
    useEffect: Io,
    useImperativeHandle: r1,
    useInsertionEffect: e1,
    useLayoutEffect: t1,
    useMemo: i1,
    useReducer: ei,
    useRef: bu,
    useState: function () {
      return ei(er);
    },
    useDebugValue: $o,
    useDeferredValue: function (e) {
      var t = Ne();
      return o1(t, K.memoizedState, e);
    },
    useTransition: function () {
      var e = ei(er)[0],
        t = Ne().memoizedState;
      return [e, t];
    },
    useMutableSource: Qu,
    useSyncExternalStore: Gu,
    useId: s1,
    unstable_isNewReconciler: !1,
  },
  oc = {
    readContext: _e,
    useCallback: l1,
    useContext: _e,
    useEffect: Io,
    useImperativeHandle: r1,
    useInsertionEffect: e1,
    useLayoutEffect: t1,
    useMemo: i1,
    useReducer: ti,
    useRef: bu,
    useState: function () {
      return ti(er);
    },
    useDebugValue: $o,
    useDeferredValue: function (e) {
      var t = Ne();
      return K === null ? (t.memoizedState = e) : o1(t, K.memoizedState, e);
    },
    useTransition: function () {
      var e = ti(er)[0],
        t = Ne().memoizedState;
      return [e, t];
    },
    useMutableSource: Qu,
    useSyncExternalStore: Gu,
    useId: s1,
    unstable_isNewReconciler: !1,
  };
function an(e, t) {
  try {
    var n = "",
      r = t;
    do (n += D3(r)), (r = r.return);
    while (r);
    var l = n;
  } catch (i) {
    l =
      `
Error generating stack: ` +
      i.message +
      `
` +
      i.stack;
  }
  return { value: e, source: t, stack: l, digest: null };
}
function ni(e, t, n) {
  return { value: e, source: null, stack: n ?? null, digest: t ?? null };
}
function Ai(e, t) {
  try {
    console.error(t.value);
  } catch (n) {
    setTimeout(function () {
      throw n;
    });
  }
}
var sc = typeof WeakMap == "function" ? WeakMap : Map;
function f1(e, t, n) {
  (n = Qe(-1, n)), (n.tag = 3), (n.payload = { element: null });
  var r = t.value;
  return (
    (n.callback = function () {
      sl || ((sl = !0), (Ji = r)), Ai(e, t);
    }),
    n
  );
}
function d1(e, t, n) {
  (n = Qe(-1, n)), (n.tag = 3);
  var r = e.type.getDerivedStateFromError;
  if (typeof r == "function") {
    var l = t.value;
    (n.payload = function () {
      return r(l);
    }),
      (n.callback = function () {
        Ai(e, t);
      });
  }
  var i = e.stateNode;
  return (
    i !== null &&
      typeof i.componentDidCatch == "function" &&
      (n.callback = function () {
        Ai(e, t),
          typeof r != "function" &&
            (ft === null ? (ft = new Set([this])) : ft.add(this));
        var o = t.stack;
        this.componentDidCatch(t.value, {
          componentStack: o !== null ? o : "",
        });
      }),
    n
  );
}
function Ys(e, t, n) {
  var r = e.pingCache;
  if (r === null) {
    r = e.pingCache = new sc();
    var l = new Set();
    r.set(t, l);
  } else (l = r.get(t)), l === void 0 && ((l = new Set()), r.set(t, l));
  l.has(n) || (l.add(n), (e = wc.bind(null, e, t, n)), t.then(e, e));
}
function Xs(e) {
  do {
    var t;
    if (
      ((t = e.tag === 13) &&
        ((t = e.memoizedState), (t = t !== null ? t.dehydrated !== null : !0)),
      t)
    )
      return e;
    e = e.return;
  } while (e !== null);
  return null;
}
function Js(e, t, n, r, l) {
  return e.mode & 1
    ? ((e.flags |= 65536), (e.lanes = l), e)
    : (e === t
        ? (e.flags |= 65536)
        : ((e.flags |= 128),
          (n.flags |= 131072),
          (n.flags &= -52805),
          n.tag === 1 &&
            (n.alternate === null
              ? (n.tag = 17)
              : ((t = Qe(-1, 1)), (t.tag = 2), ct(n, t, 1))),
          (n.lanes |= 1)),
      e);
}
var ac = Je.ReactCurrentOwner,
  pe = !1;
function ae(e, t, n, r) {
  t.child = e === null ? Zu(t, null, n, r) : on(t, e.child, n, r);
}
function qs(e, t, n, r, l) {
  n = n.render;
  var i = t.ref;
  return (
    en(t, l),
    (r = Fo(e, t, n, r, i, l)),
    (n = Bo()),
    e !== null && !pe
      ? ((t.updateQueue = e.updateQueue),
        (t.flags &= -2053),
        (e.lanes &= ~l),
        Xe(e, t, l))
      : ($ && n && ko(t), (t.flags |= 1), ae(e, t, r, l), t.child)
  );
}
function bs(e, t, n, r, l) {
  if (e === null) {
    var i = n.type;
    return typeof i == "function" &&
      !Ko(i) &&
      i.defaultProps === void 0 &&
      n.compare === null &&
      n.defaultProps === void 0
      ? ((t.tag = 15), (t.type = i), p1(e, t, i, r, l))
      : ((e = $r(n.type, null, r, t, t.mode, l)),
        (e.ref = t.ref),
        (e.return = t),
        (t.child = e));
  }
  if (((i = e.child), !(e.lanes & l))) {
    var o = i.memoizedProps;
    if (
      ((n = n.compare), (n = n !== null ? n : Gn), n(o, r) && e.ref === t.ref)
    )
      return Xe(e, t, l);
  }
  return (
    (t.flags |= 1),
    (e = pt(i, r)),
    (e.ref = t.ref),
    (e.return = t),
    (t.child = e)
  );
}
function p1(e, t, n, r, l) {
  if (e !== null) {
    var i = e.memoizedProps;
    if (Gn(i, r) && e.ref === t.ref)
      if (((pe = !1), (t.pendingProps = r = i), (e.lanes & l) !== 0))
        e.flags & 131072 && (pe = !0);
      else return (t.lanes = e.lanes), Xe(e, t, l);
  }
  return Vi(e, t, n, r, l);
}
function m1(e, t, n) {
  var r = t.pendingProps,
    l = r.children,
    i = e !== null ? e.memoizedState : null;
  if (r.mode === "hidden")
    if (!(t.mode & 1))
      (t.memoizedState = { baseLanes: 0, cachePool: null, transitions: null }),
        U(Yt, ge),
        (ge |= n);
    else {
      if (!(n & 1073741824))
        return (
          (e = i !== null ? i.baseLanes | n : n),
          (t.lanes = t.childLanes = 1073741824),
          (t.memoizedState = {
            baseLanes: e,
            cachePool: null,
            transitions: null,
          }),
          (t.updateQueue = null),
          U(Yt, ge),
          (ge |= e),
          null
        );
      (t.memoizedState = { baseLanes: 0, cachePool: null, transitions: null }),
        (r = i !== null ? i.baseLanes : n),
        U(Yt, ge),
        (ge |= r);
    }
  else
    i !== null ? ((r = i.baseLanes | n), (t.memoizedState = null)) : (r = n),
      U(Yt, ge),
      (ge |= r);
  return ae(e, t, l, n), t.child;
}
function h1(e, t) {
  var n = t.ref;
  ((e === null && n !== null) || (e !== null && e.ref !== n)) &&
    ((t.flags |= 512), (t.flags |= 2097152));
}
function Vi(e, t, n, r, l) {
  var i = he(n) ? zt : se.current;
  return (
    (i = rn(t, i)),
    en(t, l),
    (n = Fo(e, t, n, r, i, l)),
    (r = Bo()),
    e !== null && !pe
      ? ((t.updateQueue = e.updateQueue),
        (t.flags &= -2053),
        (e.lanes &= ~l),
        Xe(e, t, l))
      : ($ && r && ko(t), (t.flags |= 1), ae(e, t, n, l), t.child)
  );
}
function ea(e, t, n, r, l) {
  if (he(n)) {
    var i = !0;
    Jr(t);
  } else i = !1;
  if ((en(t, l), t.stateNode === null))
    Fr(e, t), Vu(t, n, r), $i(t, n, r, l), (r = !0);
  else if (e === null) {
    var o = t.stateNode,
      a = t.memoizedProps;
    o.props = a;
    var u = o.context,
      f = n.contextType;
    typeof f == "object" && f !== null
      ? (f = _e(f))
      : ((f = he(n) ? zt : se.current), (f = rn(t, f)));
    var c = n.getDerivedStateFromProps,
      h =
        typeof c == "function" ||
        typeof o.getSnapshotBeforeUpdate == "function";
    h ||
      (typeof o.UNSAFE_componentWillReceiveProps != "function" &&
        typeof o.componentWillReceiveProps != "function") ||
      ((a !== r || u !== f) && Ws(t, o, r, f)),
      (et = !1);
    var v = t.memoizedState;
    (o.state = v),
      nl(t, r, o, l),
      (u = t.memoizedState),
      a !== r || v !== u || me.current || et
        ? (typeof c == "function" && (Ii(t, n, c, r), (u = t.memoizedState)),
          (a = et || Zs(t, n, a, r, v, u, f))
            ? (h ||
                (typeof o.UNSAFE_componentWillMount != "function" &&
                  typeof o.componentWillMount != "function") ||
                (typeof o.componentWillMount == "function" &&
                  o.componentWillMount(),
                typeof o.UNSAFE_componentWillMount == "function" &&
                  o.UNSAFE_componentWillMount()),
              typeof o.componentDidMount == "function" && (t.flags |= 4194308))
            : (typeof o.componentDidMount == "function" && (t.flags |= 4194308),
              (t.memoizedProps = r),
              (t.memoizedState = u)),
          (o.props = r),
          (o.state = u),
          (o.context = f),
          (r = a))
        : (typeof o.componentDidMount == "function" && (t.flags |= 4194308),
          (r = !1));
  } else {
    (o = t.stateNode),
      $u(e, t),
      (a = t.memoizedProps),
      (f = t.type === t.elementType ? a : ze(t.type, a)),
      (o.props = f),
      (h = t.pendingProps),
      (v = o.context),
      (u = n.contextType),
      typeof u == "object" && u !== null
        ? (u = _e(u))
        : ((u = he(n) ? zt : se.current), (u = rn(t, u)));
    var g = n.getDerivedStateFromProps;
    (c =
      typeof g == "function" ||
      typeof o.getSnapshotBeforeUpdate == "function") ||
      (typeof o.UNSAFE_componentWillReceiveProps != "function" &&
        typeof o.componentWillReceiveProps != "function") ||
      ((a !== h || v !== u) && Ws(t, o, r, u)),
      (et = !1),
      (v = t.memoizedState),
      (o.state = v),
      nl(t, r, o, l);
    var x = t.memoizedState;
    a !== h || v !== x || me.current || et
      ? (typeof g == "function" && (Ii(t, n, g, r), (x = t.memoizedState)),
        (f = et || Zs(t, n, f, r, v, x, u) || !1)
          ? (c ||
              (typeof o.UNSAFE_componentWillUpdate != "function" &&
                typeof o.componentWillUpdate != "function") ||
              (typeof o.componentWillUpdate == "function" &&
                o.componentWillUpdate(r, x, u),
              typeof o.UNSAFE_componentWillUpdate == "function" &&
                o.UNSAFE_componentWillUpdate(r, x, u)),
            typeof o.componentDidUpdate == "function" && (t.flags |= 4),
            typeof o.getSnapshotBeforeUpdate == "function" && (t.flags |= 1024))
          : (typeof o.componentDidUpdate != "function" ||
              (a === e.memoizedProps && v === e.memoizedState) ||
              (t.flags |= 4),
            typeof o.getSnapshotBeforeUpdate != "function" ||
              (a === e.memoizedProps && v === e.memoizedState) ||
              (t.flags |= 1024),
            (t.memoizedProps = r),
            (t.memoizedState = x)),
        (o.props = r),
        (o.state = x),
        (o.context = u),
        (r = f))
      : (typeof o.componentDidUpdate != "function" ||
          (a === e.memoizedProps && v === e.memoizedState) ||
          (t.flags |= 4),
        typeof o.getSnapshotBeforeUpdate != "function" ||
          (a === e.memoizedProps && v === e.memoizedState) ||
          (t.flags |= 1024),
        (r = !1));
  }
  return Hi(e, t, n, r, i, l);
}
function Hi(e, t, n, r, l, i) {
  h1(e, t);
  var o = (t.flags & 128) !== 0;
  if (!r && !o) return l && Is(t, n, !1), Xe(e, t, i);
  (r = t.stateNode), (ac.current = t);
  var a =
    o && typeof n.getDerivedStateFromError != "function" ? null : r.render();
  return (
    (t.flags |= 1),
    e !== null && o
      ? ((t.child = on(t, e.child, null, i)), (t.child = on(t, null, a, i)))
      : ae(e, t, a, i),
    (t.memoizedState = r.state),
    l && Is(t, n, !0),
    t.child
  );
}
function v1(e) {
  var t = e.stateNode;
  t.pendingContext
    ? Bs(e, t.pendingContext, t.pendingContext !== t.context)
    : t.context && Bs(e, t.context, !1),
    Ro(e, t.containerInfo);
}
function ta(e, t, n, r, l) {
  return ln(), _o(l), (t.flags |= 256), ae(e, t, n, r), t.child;
}
var Zi = { dehydrated: null, treeContext: null, retryLane: 0 };
function Wi(e) {
  return { baseLanes: e, cachePool: null, transitions: null };
}
function g1(e, t, n) {
  var r = t.pendingProps,
    l = A.current,
    i = !1,
    o = (t.flags & 128) !== 0,
    a;
  if (
    ((a = o) ||
      (a = e !== null && e.memoizedState === null ? !1 : (l & 2) !== 0),
    a
      ? ((i = !0), (t.flags &= -129))
      : (e === null || e.memoizedState !== null) && (l |= 1),
    U(A, l & 1),
    e === null)
  )
    return (
      Fi(t),
      (e = t.memoizedState),
      e !== null && ((e = e.dehydrated), e !== null)
        ? (t.mode & 1
            ? e.data === "$!"
              ? (t.lanes = 8)
              : (t.lanes = 1073741824)
            : (t.lanes = 1),
          null)
        : ((o = r.children),
          (e = r.fallback),
          i
            ? ((r = t.mode),
              (i = t.child),
              (o = { mode: "hidden", children: o }),
              !(r & 1) && i !== null
                ? ((i.childLanes = 0), (i.pendingProps = o))
                : (i = Sl(o, r, 0, null)),
              (e = Nt(e, r, n, null)),
              (i.return = t),
              (e.return = t),
              (i.sibling = e),
              (t.child = i),
              (t.child.memoizedState = Wi(n)),
              (t.memoizedState = Zi),
              e)
            : Ao(t, o))
    );
  if (((l = e.memoizedState), l !== null && ((a = l.dehydrated), a !== null)))
    return uc(e, t, o, r, a, l, n);
  if (i) {
    (i = r.fallback), (o = t.mode), (l = e.child), (a = l.sibling);
    var u = { mode: "hidden", children: r.children };
    return (
      !(o & 1) && t.child !== l
        ? ((r = t.child),
          (r.childLanes = 0),
          (r.pendingProps = u),
          (t.deletions = null))
        : ((r = pt(l, u)), (r.subtreeFlags = l.subtreeFlags & 14680064)),
      a !== null ? (i = pt(a, i)) : ((i = Nt(i, o, n, null)), (i.flags |= 2)),
      (i.return = t),
      (r.return = t),
      (r.sibling = i),
      (t.child = r),
      (r = i),
      (i = t.child),
      (o = e.child.memoizedState),
      (o =
        o === null
          ? Wi(n)
          : {
              baseLanes: o.baseLanes | n,
              cachePool: null,
              transitions: o.transitions,
            }),
      (i.memoizedState = o),
      (i.childLanes = e.childLanes & ~n),
      (t.memoizedState = Zi),
      r
    );
  }
  return (
    (i = e.child),
    (e = i.sibling),
    (r = pt(i, { mode: "visible", children: r.children })),
    !(t.mode & 1) && (r.lanes = n),
    (r.return = t),
    (r.sibling = null),
    e !== null &&
      ((n = t.deletions),
      n === null ? ((t.deletions = [e]), (t.flags |= 16)) : n.push(e)),
    (t.child = r),
    (t.memoizedState = null),
    r
  );
}
function Ao(e, t) {
  return (
    (t = Sl({ mode: "visible", children: t }, e.mode, 0, null)),
    (t.return = e),
    (e.child = t)
  );
}
function kr(e, t, n, r) {
  return (
    r !== null && _o(r),
    on(t, e.child, null, n),
    (e = Ao(t, t.pendingProps.children)),
    (e.flags |= 2),
    (t.memoizedState = null),
    e
  );
}
function uc(e, t, n, r, l, i, o) {
  if (n)
    return t.flags & 256
      ? ((t.flags &= -257), (r = ni(Error(w(422)))), kr(e, t, o, r))
      : t.memoizedState !== null
      ? ((t.child = e.child), (t.flags |= 128), null)
      : ((i = r.fallback),
        (l = t.mode),
        (r = Sl({ mode: "visible", children: r.children }, l, 0, null)),
        (i = Nt(i, l, o, null)),
        (i.flags |= 2),
        (r.return = t),
        (i.return = t),
        (r.sibling = i),
        (t.child = r),
        t.mode & 1 && on(t, e.child, null, o),
        (t.child.memoizedState = Wi(o)),
        (t.memoizedState = Zi),
        i);
  if (!(t.mode & 1)) return kr(e, t, o, null);
  if (l.data === "$!") {
    if (((r = l.nextSibling && l.nextSibling.dataset), r)) var a = r.dgst;
    return (r = a), (i = Error(w(419))), (r = ni(i, r, void 0)), kr(e, t, o, r);
  }
  if (((a = (o & e.childLanes) !== 0), pe || a)) {
    if (((r = ee), r !== null)) {
      switch (o & -o) {
        case 4:
          l = 2;
          break;
        case 16:
          l = 8;
          break;
        case 64:
        case 128:
        case 256:
        case 512:
        case 1024:
        case 2048:
        case 4096:
        case 8192:
        case 16384:
        case 32768:
        case 65536:
        case 131072:
        case 262144:
        case 524288:
        case 1048576:
        case 2097152:
        case 4194304:
        case 8388608:
        case 16777216:
        case 33554432:
        case 67108864:
          l = 32;
          break;
        case 536870912:
          l = 268435456;
          break;
        default:
          l = 0;
      }
      (l = l & (r.suspendedLanes | o) ? 0 : l),
        l !== 0 &&
          l !== i.retryLane &&
          ((i.retryLane = l), Ye(e, l), De(r, e, l, -1));
    }
    return Go(), (r = ni(Error(w(421)))), kr(e, t, o, r);
  }
  return l.data === "$?"
    ? ((t.flags |= 128),
      (t.child = e.child),
      (t = Sc.bind(null, e)),
      (l._reactRetry = t),
      null)
    : ((e = i.treeContext),
      (xe = ut(l.nextSibling)),
      (ye = t),
      ($ = !0),
      (Te = null),
      e !== null &&
        ((Ee[je++] = Ze),
        (Ee[je++] = We),
        (Ee[je++] = Mt),
        (Ze = e.id),
        (We = e.overflow),
        (Mt = t)),
      (t = Ao(t, r.children)),
      (t.flags |= 4096),
      t);
}
function na(e, t, n) {
  e.lanes |= t;
  var r = e.alternate;
  r !== null && (r.lanes |= t), Bi(e.return, t, n);
}
function ri(e, t, n, r, l) {
  var i = e.memoizedState;
  i === null
    ? (e.memoizedState = {
        isBackwards: t,
        rendering: null,
        renderingStartTime: 0,
        last: r,
        tail: n,
        tailMode: l,
      })
    : ((i.isBackwards = t),
      (i.rendering = null),
      (i.renderingStartTime = 0),
      (i.last = r),
      (i.tail = n),
      (i.tailMode = l));
}
function x1(e, t, n) {
  var r = t.pendingProps,
    l = r.revealOrder,
    i = r.tail;
  if ((ae(e, t, r.children, n), (r = A.current), r & 2))
    (r = (r & 1) | 2), (t.flags |= 128);
  else {
    if (e !== null && e.flags & 128)
      e: for (e = t.child; e !== null; ) {
        if (e.tag === 13) e.memoizedState !== null && na(e, n, t);
        else if (e.tag === 19) na(e, n, t);
        else if (e.child !== null) {
          (e.child.return = e), (e = e.child);
          continue;
        }
        if (e === t) break e;
        for (; e.sibling === null; ) {
          if (e.return === null || e.return === t) break e;
          e = e.return;
        }
        (e.sibling.return = e.return), (e = e.sibling);
      }
    r &= 1;
  }
  if ((U(A, r), !(t.mode & 1))) t.memoizedState = null;
  else
    switch (l) {
      case "forwards":
        for (n = t.child, l = null; n !== null; )
          (e = n.alternate),
            e !== null && rl(e) === null && (l = n),
            (n = n.sibling);
        (n = l),
          n === null
            ? ((l = t.child), (t.child = null))
            : ((l = n.sibling), (n.sibling = null)),
          ri(t, !1, l, n, i);
        break;
      case "backwards":
        for (n = null, l = t.child, t.child = null; l !== null; ) {
          if (((e = l.alternate), e !== null && rl(e) === null)) {
            t.child = l;
            break;
          }
          (e = l.sibling), (l.sibling = n), (n = l), (l = e);
        }
        ri(t, !0, n, null, i);
        break;
      case "together":
        ri(t, !1, null, null, void 0);
        break;
      default:
        t.memoizedState = null;
    }
  return t.child;
}
function Fr(e, t) {
  !(t.mode & 1) &&
    e !== null &&
    ((e.alternate = null), (t.alternate = null), (t.flags |= 2));
}
function Xe(e, t, n) {
  if (
    (e !== null && (t.dependencies = e.dependencies),
    (Rt |= t.lanes),
    !(n & t.childLanes))
  )
    return null;
  if (e !== null && t.child !== e.child) throw Error(w(153));
  if (t.child !== null) {
    for (
      e = t.child, n = pt(e, e.pendingProps), t.child = n, n.return = t;
      e.sibling !== null;

    )
      (e = e.sibling), (n = n.sibling = pt(e, e.pendingProps)), (n.return = t);
    n.sibling = null;
  }
  return t.child;
}
function cc(e, t, n) {
  switch (t.tag) {
    case 3:
      v1(t), ln();
      break;
    case 5:
      Wu(t);
      break;
    case 1:
      he(t.type) && Jr(t);
      break;
    case 4:
      Ro(t, t.stateNode.containerInfo);
      break;
    case 10:
      var r = t.type._context,
        l = t.memoizedProps.value;
      U(el, r._currentValue), (r._currentValue = l);
      break;
    case 13:
      if (((r = t.memoizedState), r !== null))
        return r.dehydrated !== null
          ? (U(A, A.current & 1), (t.flags |= 128), null)
          : n & t.child.childLanes
          ? g1(e, t, n)
          : (U(A, A.current & 1),
            (e = Xe(e, t, n)),
            e !== null ? e.sibling : null);
      U(A, A.current & 1);
      break;
    case 19:
      if (((r = (n & t.childLanes) !== 0), e.flags & 128)) {
        if (r) return x1(e, t, n);
        t.flags |= 128;
      }
      if (
        ((l = t.memoizedState),
        l !== null &&
          ((l.rendering = null), (l.tail = null), (l.lastEffect = null)),
        U(A, A.current),
        r)
      )
        break;
      return null;
    case 22:
    case 23:
      return (t.lanes = 0), m1(e, t, n);
  }
  return Xe(e, t, n);
}
var y1, Qi, C1, w1;
y1 = function (e, t) {
  for (var n = t.child; n !== null; ) {
    if (n.tag === 5 || n.tag === 6) e.appendChild(n.stateNode);
    else if (n.tag !== 4 && n.child !== null) {
      (n.child.return = n), (n = n.child);
      continue;
    }
    if (n === t) break;
    for (; n.sibling === null; ) {
      if (n.return === null || n.return === t) return;
      n = n.return;
    }
    (n.sibling.return = n.return), (n = n.sibling);
  }
};
Qi = function () {};
C1 = function (e, t, n, r) {
  var l = e.memoizedProps;
  if (l !== r) {
    (e = t.stateNode), Lt(Ae.current);
    var i = null;
    switch (n) {
      case "input":
        (l = mi(e, l)), (r = mi(e, r)), (i = []);
        break;
      case "select":
        (l = H({}, l, { value: void 0 })),
          (r = H({}, r, { value: void 0 })),
          (i = []);
        break;
      case "textarea":
        (l = gi(e, l)), (r = gi(e, r)), (i = []);
        break;
      default:
        typeof l.onClick != "function" &&
          typeof r.onClick == "function" &&
          (e.onclick = Yr);
    }
    yi(n, r);
    var o;
    n = null;
    for (f in l)
      if (!r.hasOwnProperty(f) && l.hasOwnProperty(f) && l[f] != null)
        if (f === "style") {
          var a = l[f];
          for (o in a) a.hasOwnProperty(o) && (n || (n = {}), (n[o] = ""));
        } else
          f !== "dangerouslySetInnerHTML" &&
            f !== "children" &&
            f !== "suppressContentEditableWarning" &&
            f !== "suppressHydrationWarning" &&
            f !== "autoFocus" &&
            ($n.hasOwnProperty(f)
              ? i || (i = [])
              : (i = i || []).push(f, null));
    for (f in r) {
      var u = r[f];
      if (
        ((a = l != null ? l[f] : void 0),
        r.hasOwnProperty(f) && u !== a && (u != null || a != null))
      )
        if (f === "style")
          if (a) {
            for (o in a)
              !a.hasOwnProperty(o) ||
                (u && u.hasOwnProperty(o)) ||
                (n || (n = {}), (n[o] = ""));
            for (o in u)
              u.hasOwnProperty(o) &&
                a[o] !== u[o] &&
                (n || (n = {}), (n[o] = u[o]));
          } else n || (i || (i = []), i.push(f, n)), (n = u);
        else
          f === "dangerouslySetInnerHTML"
            ? ((u = u ? u.__html : void 0),
              (a = a ? a.__html : void 0),
              u != null && a !== u && (i = i || []).push(f, u))
            : f === "children"
            ? (typeof u != "string" && typeof u != "number") ||
              (i = i || []).push(f, "" + u)
            : f !== "suppressContentEditableWarning" &&
              f !== "suppressHydrationWarning" &&
              ($n.hasOwnProperty(f)
                ? (u != null && f === "onScroll" && F("scroll", e),
                  i || a === u || (i = []))
                : (i = i || []).push(f, u));
    }
    n && (i = i || []).push("style", n);
    var f = i;
    (t.updateQueue = f) && (t.flags |= 4);
  }
};
w1 = function (e, t, n, r) {
  n !== r && (t.flags |= 4);
};
function En(e, t) {
  if (!$)
    switch (e.tailMode) {
      case "hidden":
        t = e.tail;
        for (var n = null; t !== null; )
          t.alternate !== null && (n = t), (t = t.sibling);
        n === null ? (e.tail = null) : (n.sibling = null);
        break;
      case "collapsed":
        n = e.tail;
        for (var r = null; n !== null; )
          n.alternate !== null && (r = n), (n = n.sibling);
        r === null
          ? t || e.tail === null
            ? (e.tail = null)
            : (e.tail.sibling = null)
          : (r.sibling = null);
    }
}
function ie(e) {
  var t = e.alternate !== null && e.alternate.child === e.child,
    n = 0,
    r = 0;
  if (t)
    for (var l = e.child; l !== null; )
      (n |= l.lanes | l.childLanes),
        (r |= l.subtreeFlags & 14680064),
        (r |= l.flags & 14680064),
        (l.return = e),
        (l = l.sibling);
  else
    for (l = e.child; l !== null; )
      (n |= l.lanes | l.childLanes),
        (r |= l.subtreeFlags),
        (r |= l.flags),
        (l.return = e),
        (l = l.sibling);
  return (e.subtreeFlags |= r), (e.childLanes = n), t;
}
function fc(e, t, n) {
  var r = t.pendingProps;
  switch ((Lo(t), t.tag)) {
    case 2:
    case 16:
    case 15:
    case 0:
    case 11:
    case 7:
    case 8:
    case 12:
    case 9:
    case 14:
      return ie(t), null;
    case 1:
      return he(t.type) && Xr(), ie(t), null;
    case 3:
      return (
        (r = t.stateNode),
        sn(),
        B(me),
        B(se),
        Oo(),
        r.pendingContext &&
          ((r.context = r.pendingContext), (r.pendingContext = null)),
        (e === null || e.child === null) &&
          (Er(t)
            ? (t.flags |= 4)
            : e === null ||
              (e.memoizedState.isDehydrated && !(t.flags & 256)) ||
              ((t.flags |= 1024), Te !== null && (eo(Te), (Te = null)))),
        Qi(e, t),
        ie(t),
        null
      );
    case 5:
      Do(t);
      var l = Lt(qn.current);
      if (((n = t.type), e !== null && t.stateNode != null))
        C1(e, t, n, r, l),
          e.ref !== t.ref && ((t.flags |= 512), (t.flags |= 2097152));
      else {
        if (!r) {
          if (t.stateNode === null) throw Error(w(166));
          return ie(t), null;
        }
        if (((e = Lt(Ae.current)), Er(t))) {
          (r = t.stateNode), (n = t.type);
          var i = t.memoizedProps;
          switch (((r[Ie] = t), (r[Xn] = i), (e = (t.mode & 1) !== 0), n)) {
            case "dialog":
              F("cancel", r), F("close", r);
              break;
            case "iframe":
            case "object":
            case "embed":
              F("load", r);
              break;
            case "video":
            case "audio":
              for (l = 0; l < Nn.length; l++) F(Nn[l], r);
              break;
            case "source":
              F("error", r);
              break;
            case "img":
            case "image":
            case "link":
              F("error", r), F("load", r);
              break;
            case "details":
              F("toggle", r);
              break;
            case "input":
              fs(r, i), F("invalid", r);
              break;
            case "select":
              (r._wrapperState = { wasMultiple: !!i.multiple }),
                F("invalid", r);
              break;
            case "textarea":
              ps(r, i), F("invalid", r);
          }
          yi(n, i), (l = null);
          for (var o in i)
            if (i.hasOwnProperty(o)) {
              var a = i[o];
              o === "children"
                ? typeof a == "string"
                  ? r.textContent !== a &&
                    (i.suppressHydrationWarning !== !0 &&
                      Sr(r.textContent, a, e),
                    (l = ["children", a]))
                  : typeof a == "number" &&
                    r.textContent !== "" + a &&
                    (i.suppressHydrationWarning !== !0 &&
                      Sr(r.textContent, a, e),
                    (l = ["children", "" + a]))
                : $n.hasOwnProperty(o) &&
                  a != null &&
                  o === "onScroll" &&
                  F("scroll", r);
            }
          switch (n) {
            case "input":
              mr(r), ds(r, i, !0);
              break;
            case "textarea":
              mr(r), ms(r);
              break;
            case "select":
            case "option":
              break;
            default:
              typeof i.onClick == "function" && (r.onclick = Yr);
          }
          (r = l), (t.updateQueue = r), r !== null && (t.flags |= 4);
        } else {
          (o = l.nodeType === 9 ? l : l.ownerDocument),
            e === "http://www.w3.org/1999/xhtml" && (e = Ka(n)),
            e === "http://www.w3.org/1999/xhtml"
              ? n === "script"
                ? ((e = o.createElement("div")),
                  (e.innerHTML = "<script></script>"),
                  (e = e.removeChild(e.firstChild)))
                : typeof r.is == "string"
                ? (e = o.createElement(n, { is: r.is }))
                : ((e = o.createElement(n)),
                  n === "select" &&
                    ((o = e),
                    r.multiple
                      ? (o.multiple = !0)
                      : r.size && (o.size = r.size)))
              : (e = o.createElementNS(e, n)),
            (e[Ie] = t),
            (e[Xn] = r),
            y1(e, t, !1, !1),
            (t.stateNode = e);
          e: {
            switch (((o = Ci(n, r)), n)) {
              case "dialog":
                F("cancel", e), F("close", e), (l = r);
                break;
              case "iframe":
              case "object":
              case "embed":
                F("load", e), (l = r);
                break;
              case "video":
              case "audio":
                for (l = 0; l < Nn.length; l++) F(Nn[l], e);
                l = r;
                break;
              case "source":
                F("error", e), (l = r);
                break;
              case "img":
              case "image":
              case "link":
                F("error", e), F("load", e), (l = r);
                break;
              case "details":
                F("toggle", e), (l = r);
                break;
              case "input":
                fs(e, r), (l = mi(e, r)), F("invalid", e);
                break;
              case "option":
                l = r;
                break;
              case "select":
                (e._wrapperState = { wasMultiple: !!r.multiple }),
                  (l = H({}, r, { value: void 0 })),
                  F("invalid", e);
                break;
              case "textarea":
                ps(e, r), (l = gi(e, r)), F("invalid", e);
                break;
              default:
                l = r;
            }
            yi(n, l), (a = l);
            for (i in a)
              if (a.hasOwnProperty(i)) {
                var u = a[i];
                i === "style"
                  ? Ja(e, u)
                  : i === "dangerouslySetInnerHTML"
                  ? ((u = u ? u.__html : void 0), u != null && Ya(e, u))
                  : i === "children"
                  ? typeof u == "string"
                    ? (n !== "textarea" || u !== "") && An(e, u)
                    : typeof u == "number" && An(e, "" + u)
                  : i !== "suppressContentEditableWarning" &&
                    i !== "suppressHydrationWarning" &&
                    i !== "autoFocus" &&
                    ($n.hasOwnProperty(i)
                      ? u != null && i === "onScroll" && F("scroll", e)
                      : u != null && co(e, i, u, o));
              }
            switch (n) {
              case "input":
                mr(e), ds(e, r, !1);
                break;
              case "textarea":
                mr(e), ms(e);
                break;
              case "option":
                r.value != null && e.setAttribute("value", "" + mt(r.value));
                break;
              case "select":
                (e.multiple = !!r.multiple),
                  (i = r.value),
                  i != null
                    ? Xt(e, !!r.multiple, i, !1)
                    : r.defaultValue != null &&
                      Xt(e, !!r.multiple, r.defaultValue, !0);
                break;
              default:
                typeof l.onClick == "function" && (e.onclick = Yr);
            }
            switch (n) {
              case "button":
              case "input":
              case "select":
              case "textarea":
                r = !!r.autoFocus;
                break e;
              case "img":
                r = !0;
                break e;
              default:
                r = !1;
            }
          }
          r && (t.flags |= 4);
        }
        t.ref !== null && ((t.flags |= 512), (t.flags |= 2097152));
      }
      return ie(t), null;
    case 6:
      if (e && t.stateNode != null) w1(e, t, e.memoizedProps, r);
      else {
        if (typeof r != "string" && t.stateNode === null) throw Error(w(166));
        if (((n = Lt(qn.current)), Lt(Ae.current), Er(t))) {
          if (
            ((r = t.stateNode),
            (n = t.memoizedProps),
            (r[Ie] = t),
            (i = r.nodeValue !== n) && ((e = ye), e !== null))
          )
            switch (e.tag) {
              case 3:
                Sr(r.nodeValue, n, (e.mode & 1) !== 0);
                break;
              case 5:
                e.memoizedProps.suppressHydrationWarning !== !0 &&
                  Sr(r.nodeValue, n, (e.mode & 1) !== 0);
            }
          i && (t.flags |= 4);
        } else
          (r = (n.nodeType === 9 ? n : n.ownerDocument).createTextNode(r)),
            (r[Ie] = t),
            (t.stateNode = r);
      }
      return ie(t), null;
    case 13:
      if (
        (B(A),
        (r = t.memoizedState),
        e === null ||
          (e.memoizedState !== null && e.memoizedState.dehydrated !== null))
      ) {
        if ($ && xe !== null && t.mode & 1 && !(t.flags & 128))
          Bu(), ln(), (t.flags |= 98560), (i = !1);
        else if (((i = Er(t)), r !== null && r.dehydrated !== null)) {
          if (e === null) {
            if (!i) throw Error(w(318));
            if (
              ((i = t.memoizedState),
              (i = i !== null ? i.dehydrated : null),
              !i)
            )
              throw Error(w(317));
            i[Ie] = t;
          } else
            ln(), !(t.flags & 128) && (t.memoizedState = null), (t.flags |= 4);
          ie(t), (i = !1);
        } else Te !== null && (eo(Te), (Te = null)), (i = !0);
        if (!i) return t.flags & 65536 ? t : null;
      }
      return t.flags & 128
        ? ((t.lanes = n), t)
        : ((r = r !== null),
          r !== (e !== null && e.memoizedState !== null) &&
            r &&
            ((t.child.flags |= 8192),
            t.mode & 1 &&
              (e === null || A.current & 1 ? Y === 0 && (Y = 3) : Go())),
          t.updateQueue !== null && (t.flags |= 4),
          ie(t),
          null);
    case 4:
      return (
        sn(), Qi(e, t), e === null && Kn(t.stateNode.containerInfo), ie(t), null
      );
    case 10:
      return zo(t.type._context), ie(t), null;
    case 17:
      return he(t.type) && Xr(), ie(t), null;
    case 19:
      if ((B(A), (i = t.memoizedState), i === null)) return ie(t), null;
      if (((r = (t.flags & 128) !== 0), (o = i.rendering), o === null))
        if (r) En(i, !1);
        else {
          if (Y !== 0 || (e !== null && e.flags & 128))
            for (e = t.child; e !== null; ) {
              if (((o = rl(e)), o !== null)) {
                for (
                  t.flags |= 128,
                    En(i, !1),
                    r = o.updateQueue,
                    r !== null && ((t.updateQueue = r), (t.flags |= 4)),
                    t.subtreeFlags = 0,
                    r = n,
                    n = t.child;
                  n !== null;

                )
                  (i = n),
                    (e = r),
                    (i.flags &= 14680066),
                    (o = i.alternate),
                    o === null
                      ? ((i.childLanes = 0),
                        (i.lanes = e),
                        (i.child = null),
                        (i.subtreeFlags = 0),
                        (i.memoizedProps = null),
                        (i.memoizedState = null),
                        (i.updateQueue = null),
                        (i.dependencies = null),
                        (i.stateNode = null))
                      : ((i.childLanes = o.childLanes),
                        (i.lanes = o.lanes),
                        (i.child = o.child),
                        (i.subtreeFlags = 0),
                        (i.deletions = null),
                        (i.memoizedProps = o.memoizedProps),
                        (i.memoizedState = o.memoizedState),
                        (i.updateQueue = o.updateQueue),
                        (i.type = o.type),
                        (e = o.dependencies),
                        (i.dependencies =
                          e === null
                            ? null
                            : {
                                lanes: e.lanes,
                                firstContext: e.firstContext,
                              })),
                    (n = n.sibling);
                return U(A, (A.current & 1) | 2), t.child;
              }
              e = e.sibling;
            }
          i.tail !== null &&
            Q() > un &&
            ((t.flags |= 128), (r = !0), En(i, !1), (t.lanes = 4194304));
        }
      else {
        if (!r)
          if (((e = rl(o)), e !== null)) {
            if (
              ((t.flags |= 128),
              (r = !0),
              (n = e.updateQueue),
              n !== null && ((t.updateQueue = n), (t.flags |= 4)),
              En(i, !0),
              i.tail === null && i.tailMode === "hidden" && !o.alternate && !$)
            )
              return ie(t), null;
          } else
            2 * Q() - i.renderingStartTime > un &&
              n !== 1073741824 &&
              ((t.flags |= 128), (r = !0), En(i, !1), (t.lanes = 4194304));
        i.isBackwards
          ? ((o.sibling = t.child), (t.child = o))
          : ((n = i.last),
            n !== null ? (n.sibling = o) : (t.child = o),
            (i.last = o));
      }
      return i.tail !== null
        ? ((t = i.tail),
          (i.rendering = t),
          (i.tail = t.sibling),
          (i.renderingStartTime = Q()),
          (t.sibling = null),
          (n = A.current),
          U(A, r ? (n & 1) | 2 : n & 1),
          t)
        : (ie(t), null);
    case 22:
    case 23:
      return (
        Qo(),
        (r = t.memoizedState !== null),
        e !== null && (e.memoizedState !== null) !== r && (t.flags |= 8192),
        r && t.mode & 1
          ? ge & 1073741824 && (ie(t), t.subtreeFlags & 6 && (t.flags |= 8192))
          : ie(t),
        null
      );
    case 24:
      return null;
    case 25:
      return null;
  }
  throw Error(w(156, t.tag));
}
function dc(e, t) {
  switch ((Lo(t), t.tag)) {
    case 1:
      return (
        he(t.type) && Xr(),
        (e = t.flags),
        e & 65536 ? ((t.flags = (e & -65537) | 128), t) : null
      );
    case 3:
      return (
        sn(),
        B(me),
        B(se),
        Oo(),
        (e = t.flags),
        e & 65536 && !(e & 128) ? ((t.flags = (e & -65537) | 128), t) : null
      );
    case 5:
      return Do(t), null;
    case 13:
      if ((B(A), (e = t.memoizedState), e !== null && e.dehydrated !== null)) {
        if (t.alternate === null) throw Error(w(340));
        ln();
      }
      return (
        (e = t.flags), e & 65536 ? ((t.flags = (e & -65537) | 128), t) : null
      );
    case 19:
      return B(A), null;
    case 4:
      return sn(), null;
    case 10:
      return zo(t.type._context), null;
    case 22:
    case 23:
      return Qo(), null;
    case 24:
      return null;
    default:
      return null;
  }
}
var Lr = !1,
  oe = !1,
  pc = typeof WeakSet == "function" ? WeakSet : Set,
  k = null;
function Kt(e, t) {
  var n = e.ref;
  if (n !== null)
    if (typeof n == "function")
      try {
        n(null);
      } catch (r) {
        Z(e, t, r);
      }
    else n.current = null;
}
function Gi(e, t, n) {
  try {
    n();
  } catch (r) {
    Z(e, t, r);
  }
}
var ra = !1;
function mc(e, t) {
  if (((zi = Qr), (e = ku()), jo(e))) {
    if ("selectionStart" in e)
      var n = { start: e.selectionStart, end: e.selectionEnd };
    else
      e: {
        n = ((n = e.ownerDocument) && n.defaultView) || window;
        var r = n.getSelection && n.getSelection();
        if (r && r.rangeCount !== 0) {
          n = r.anchorNode;
          var l = r.anchorOffset,
            i = r.focusNode;
          r = r.focusOffset;
          try {
            n.nodeType, i.nodeType;
          } catch {
            n = null;
            break e;
          }
          var o = 0,
            a = -1,
            u = -1,
            f = 0,
            c = 0,
            h = e,
            v = null;
          t: for (;;) {
            for (
              var g;
              h !== n || (l !== 0 && h.nodeType !== 3) || (a = o + l),
                h !== i || (r !== 0 && h.nodeType !== 3) || (u = o + r),
                h.nodeType === 3 && (o += h.nodeValue.length),
                (g = h.firstChild) !== null;

            )
              (v = h), (h = g);
            for (;;) {
              if (h === e) break t;
              if (
                (v === n && ++f === l && (a = o),
                v === i && ++c === r && (u = o),
                (g = h.nextSibling) !== null)
              )
                break;
              (h = v), (v = h.parentNode);
            }
            h = g;
          }
          n = a === -1 || u === -1 ? null : { start: a, end: u };
        } else n = null;
      }
    n = n || { start: 0, end: 0 };
  } else n = null;
  for (Mi = { focusedElem: e, selectionRange: n }, Qr = !1, k = t; k !== null; )
    if (((t = k), (e = t.child), (t.subtreeFlags & 1028) !== 0 && e !== null))
      (e.return = t), (k = e);
    else
      for (; k !== null; ) {
        t = k;
        try {
          var x = t.alternate;
          if (t.flags & 1024)
            switch (t.tag) {
              case 0:
              case 11:
              case 15:
                break;
              case 1:
                if (x !== null) {
                  var C = x.memoizedProps,
                    j = x.memoizedState,
                    p = t.stateNode,
                    d = p.getSnapshotBeforeUpdate(
                      t.elementType === t.type ? C : ze(t.type, C),
                      j
                    );
                  p.__reactInternalSnapshotBeforeUpdate = d;
                }
                break;
              case 3:
                var m = t.stateNode.containerInfo;
                m.nodeType === 1
                  ? (m.textContent = "")
                  : m.nodeType === 9 &&
                    m.documentElement &&
                    m.removeChild(m.documentElement);
                break;
              case 5:
              case 6:
              case 4:
              case 17:
                break;
              default:
                throw Error(w(163));
            }
        } catch (y) {
          Z(t, t.return, y);
        }
        if (((e = t.sibling), e !== null)) {
          (e.return = t.return), (k = e);
          break;
        }
        k = t.return;
      }
  return (x = ra), (ra = !1), x;
}
function Fn(e, t, n) {
  var r = t.updateQueue;
  if (((r = r !== null ? r.lastEffect : null), r !== null)) {
    var l = (r = r.next);
    do {
      if ((l.tag & e) === e) {
        var i = l.destroy;
        (l.destroy = void 0), i !== void 0 && Gi(t, n, i);
      }
      l = l.next;
    } while (l !== r);
  }
}
function Cl(e, t) {
  if (
    ((t = t.updateQueue), (t = t !== null ? t.lastEffect : null), t !== null)
  ) {
    var n = (t = t.next);
    do {
      if ((n.tag & e) === e) {
        var r = n.create;
        n.destroy = r();
      }
      n = n.next;
    } while (n !== t);
  }
}
function Ki(e) {
  var t = e.ref;
  if (t !== null) {
    var n = e.stateNode;
    switch (e.tag) {
      case 5:
        e = n;
        break;
      default:
        e = n;
    }
    typeof t == "function" ? t(e) : (t.current = e);
  }
}
function S1(e) {
  var t = e.alternate;
  t !== null && ((e.alternate = null), S1(t)),
    (e.child = null),
    (e.deletions = null),
    (e.sibling = null),
    e.tag === 5 &&
      ((t = e.stateNode),
      t !== null &&
        (delete t[Ie], delete t[Xn], delete t[Di], delete t[X0], delete t[J0])),
    (e.stateNode = null),
    (e.return = null),
    (e.dependencies = null),
    (e.memoizedProps = null),
    (e.memoizedState = null),
    (e.pendingProps = null),
    (e.stateNode = null),
    (e.updateQueue = null);
}
function E1(e) {
  return e.tag === 5 || e.tag === 3 || e.tag === 4;
}
function la(e) {
  e: for (;;) {
    for (; e.sibling === null; ) {
      if (e.return === null || E1(e.return)) return null;
      e = e.return;
    }
    for (
      e.sibling.return = e.return, e = e.sibling;
      e.tag !== 5 && e.tag !== 6 && e.tag !== 18;

    ) {
      if (e.flags & 2 || e.child === null || e.tag === 4) continue e;
      (e.child.return = e), (e = e.child);
    }
    if (!(e.flags & 2)) return e.stateNode;
  }
}
function Yi(e, t, n) {
  var r = e.tag;
  if (r === 5 || r === 6)
    (e = e.stateNode),
      t
        ? n.nodeType === 8
          ? n.parentNode.insertBefore(e, t)
          : n.insertBefore(e, t)
        : (n.nodeType === 8
            ? ((t = n.parentNode), t.insertBefore(e, n))
            : ((t = n), t.appendChild(e)),
          (n = n._reactRootContainer),
          n != null || t.onclick !== null || (t.onclick = Yr));
  else if (r !== 4 && ((e = e.child), e !== null))
    for (Yi(e, t, n), e = e.sibling; e !== null; ) Yi(e, t, n), (e = e.sibling);
}
function Xi(e, t, n) {
  var r = e.tag;
  if (r === 5 || r === 6)
    (e = e.stateNode), t ? n.insertBefore(e, t) : n.appendChild(e);
  else if (r !== 4 && ((e = e.child), e !== null))
    for (Xi(e, t, n), e = e.sibling; e !== null; ) Xi(e, t, n), (e = e.sibling);
}
var te = null,
  Me = !1;
function qe(e, t, n) {
  for (n = n.child; n !== null; ) j1(e, t, n), (n = n.sibling);
}
function j1(e, t, n) {
  if ($e && typeof $e.onCommitFiberUnmount == "function")
    try {
      $e.onCommitFiberUnmount(dl, n);
    } catch {}
  switch (n.tag) {
    case 5:
      oe || Kt(n, t);
    case 6:
      var r = te,
        l = Me;
      (te = null),
        qe(e, t, n),
        (te = r),
        (Me = l),
        te !== null &&
          (Me
            ? ((e = te),
              (n = n.stateNode),
              e.nodeType === 8 ? e.parentNode.removeChild(n) : e.removeChild(n))
            : te.removeChild(n.stateNode));
      break;
    case 18:
      te !== null &&
        (Me
          ? ((e = te),
            (n = n.stateNode),
            e.nodeType === 8
              ? Xl(e.parentNode, n)
              : e.nodeType === 1 && Xl(e, n),
            Wn(e))
          : Xl(te, n.stateNode));
      break;
    case 4:
      (r = te),
        (l = Me),
        (te = n.stateNode.containerInfo),
        (Me = !0),
        qe(e, t, n),
        (te = r),
        (Me = l);
      break;
    case 0:
    case 11:
    case 14:
    case 15:
      if (
        !oe &&
        ((r = n.updateQueue), r !== null && ((r = r.lastEffect), r !== null))
      ) {
        l = r = r.next;
        do {
          var i = l,
            o = i.destroy;
          (i = i.tag),
            o !== void 0 && (i & 2 || i & 4) && Gi(n, t, o),
            (l = l.next);
        } while (l !== r);
      }
      qe(e, t, n);
      break;
    case 1:
      if (
        !oe &&
        (Kt(n, t),
        (r = n.stateNode),
        typeof r.componentWillUnmount == "function")
      )
        try {
          (r.props = n.memoizedProps),
            (r.state = n.memoizedState),
            r.componentWillUnmount();
        } catch (a) {
          Z(n, t, a);
        }
      qe(e, t, n);
      break;
    case 21:
      qe(e, t, n);
      break;
    case 22:
      n.mode & 1
        ? ((oe = (r = oe) || n.memoizedState !== null), qe(e, t, n), (oe = r))
        : qe(e, t, n);
      break;
    default:
      qe(e, t, n);
  }
}
function ia(e) {
  var t = e.updateQueue;
  if (t !== null) {
    e.updateQueue = null;
    var n = e.stateNode;
    n === null && (n = e.stateNode = new pc()),
      t.forEach(function (r) {
        var l = Ec.bind(null, e, r);
        n.has(r) || (n.add(r), r.then(l, l));
      });
  }
}
function Pe(e, t) {
  var n = t.deletions;
  if (n !== null)
    for (var r = 0; r < n.length; r++) {
      var l = n[r];
      try {
        var i = e,
          o = t,
          a = o;
        e: for (; a !== null; ) {
          switch (a.tag) {
            case 5:
              (te = a.stateNode), (Me = !1);
              break e;
            case 3:
              (te = a.stateNode.containerInfo), (Me = !0);
              break e;
            case 4:
              (te = a.stateNode.containerInfo), (Me = !0);
              break e;
          }
          a = a.return;
        }
        if (te === null) throw Error(w(160));
        j1(i, o, l), (te = null), (Me = !1);
        var u = l.alternate;
        u !== null && (u.return = null), (l.return = null);
      } catch (f) {
        Z(l, t, f);
      }
    }
  if (t.subtreeFlags & 12854)
    for (t = t.child; t !== null; ) k1(t, e), (t = t.sibling);
}
function k1(e, t) {
  var n = e.alternate,
    r = e.flags;
  switch (e.tag) {
    case 0:
    case 11:
    case 14:
    case 15:
      if ((Pe(t, e), Fe(e), r & 4)) {
        try {
          Fn(3, e, e.return), Cl(3, e);
        } catch (C) {
          Z(e, e.return, C);
        }
        try {
          Fn(5, e, e.return);
        } catch (C) {
          Z(e, e.return, C);
        }
      }
      break;
    case 1:
      Pe(t, e), Fe(e), r & 512 && n !== null && Kt(n, n.return);
      break;
    case 5:
      if (
        (Pe(t, e),
        Fe(e),
        r & 512 && n !== null && Kt(n, n.return),
        e.flags & 32)
      ) {
        var l = e.stateNode;
        try {
          An(l, "");
        } catch (C) {
          Z(e, e.return, C);
        }
      }
      if (r & 4 && ((l = e.stateNode), l != null)) {
        var i = e.memoizedProps,
          o = n !== null ? n.memoizedProps : i,
          a = e.type,
          u = e.updateQueue;
        if (((e.updateQueue = null), u !== null))
          try {
            a === "input" && i.type === "radio" && i.name != null && Qa(l, i),
              Ci(a, o);
            var f = Ci(a, i);
            for (o = 0; o < u.length; o += 2) {
              var c = u[o],
                h = u[o + 1];
              c === "style"
                ? Ja(l, h)
                : c === "dangerouslySetInnerHTML"
                ? Ya(l, h)
                : c === "children"
                ? An(l, h)
                : co(l, c, h, f);
            }
            switch (a) {
              case "input":
                hi(l, i);
                break;
              case "textarea":
                Ga(l, i);
                break;
              case "select":
                var v = l._wrapperState.wasMultiple;
                l._wrapperState.wasMultiple = !!i.multiple;
                var g = i.value;
                g != null
                  ? Xt(l, !!i.multiple, g, !1)
                  : v !== !!i.multiple &&
                    (i.defaultValue != null
                      ? Xt(l, !!i.multiple, i.defaultValue, !0)
                      : Xt(l, !!i.multiple, i.multiple ? [] : "", !1));
            }
            l[Xn] = i;
          } catch (C) {
            Z(e, e.return, C);
          }
      }
      break;
    case 6:
      if ((Pe(t, e), Fe(e), r & 4)) {
        if (e.stateNode === null) throw Error(w(162));
        (l = e.stateNode), (i = e.memoizedProps);
        try {
          l.nodeValue = i;
        } catch (C) {
          Z(e, e.return, C);
        }
      }
      break;
    case 3:
      if (
        (Pe(t, e), Fe(e), r & 4 && n !== null && n.memoizedState.isDehydrated)
      )
        try {
          Wn(t.containerInfo);
        } catch (C) {
          Z(e, e.return, C);
        }
      break;
    case 4:
      Pe(t, e), Fe(e);
      break;
    case 13:
      Pe(t, e),
        Fe(e),
        (l = e.child),
        l.flags & 8192 &&
          ((i = l.memoizedState !== null),
          (l.stateNode.isHidden = i),
          !i ||
            (l.alternate !== null && l.alternate.memoizedState !== null) ||
            (Zo = Q())),
        r & 4 && ia(e);
      break;
    case 22:
      if (
        ((c = n !== null && n.memoizedState !== null),
        e.mode & 1 ? ((oe = (f = oe) || c), Pe(t, e), (oe = f)) : Pe(t, e),
        Fe(e),
        r & 8192)
      ) {
        if (
          ((f = e.memoizedState !== null),
          (e.stateNode.isHidden = f) && !c && e.mode & 1)
        )
          for (k = e, c = e.child; c !== null; ) {
            for (h = k = c; k !== null; ) {
              switch (((v = k), (g = v.child), v.tag)) {
                case 0:
                case 11:
                case 14:
                case 15:
                  Fn(4, v, v.return);
                  break;
                case 1:
                  Kt(v, v.return);
                  var x = v.stateNode;
                  if (typeof x.componentWillUnmount == "function") {
                    (r = v), (n = v.return);
                    try {
                      (t = r),
                        (x.props = t.memoizedProps),
                        (x.state = t.memoizedState),
                        x.componentWillUnmount();
                    } catch (C) {
                      Z(r, n, C);
                    }
                  }
                  break;
                case 5:
                  Kt(v, v.return);
                  break;
                case 22:
                  if (v.memoizedState !== null) {
                    sa(h);
                    continue;
                  }
              }
              g !== null ? ((g.return = v), (k = g)) : sa(h);
            }
            c = c.sibling;
          }
        e: for (c = null, h = e; ; ) {
          if (h.tag === 5) {
            if (c === null) {
              c = h;
              try {
                (l = h.stateNode),
                  f
                    ? ((i = l.style),
                      typeof i.setProperty == "function"
                        ? i.setProperty("display", "none", "important")
                        : (i.display = "none"))
                    : ((a = h.stateNode),
                      (u = h.memoizedProps.style),
                      (o =
                        u != null && u.hasOwnProperty("display")
                          ? u.display
                          : null),
                      (a.style.display = Xa("display", o)));
              } catch (C) {
                Z(e, e.return, C);
              }
            }
          } else if (h.tag === 6) {
            if (c === null)
              try {
                h.stateNode.nodeValue = f ? "" : h.memoizedProps;
              } catch (C) {
                Z(e, e.return, C);
              }
          } else if (
            ((h.tag !== 22 && h.tag !== 23) ||
              h.memoizedState === null ||
              h === e) &&
            h.child !== null
          ) {
            (h.child.return = h), (h = h.child);
            continue;
          }
          if (h === e) break e;
          for (; h.sibling === null; ) {
            if (h.return === null || h.return === e) break e;
            c === h && (c = null), (h = h.return);
          }
          c === h && (c = null), (h.sibling.return = h.return), (h = h.sibling);
        }
      }
      break;
    case 19:
      Pe(t, e), Fe(e), r & 4 && ia(e);
      break;
    case 21:
      break;
    default:
      Pe(t, e), Fe(e);
  }
}
function Fe(e) {
  var t = e.flags;
  if (t & 2) {
    try {
      e: {
        for (var n = e.return; n !== null; ) {
          if (E1(n)) {
            var r = n;
            break e;
          }
          n = n.return;
        }
        throw Error(w(160));
      }
      switch (r.tag) {
        case 5:
          var l = r.stateNode;
          r.flags & 32 && (An(l, ""), (r.flags &= -33));
          var i = la(e);
          Xi(e, i, l);
          break;
        case 3:
        case 4:
          var o = r.stateNode.containerInfo,
            a = la(e);
          Yi(e, a, o);
          break;
        default:
          throw Error(w(161));
      }
    } catch (u) {
      Z(e, e.return, u);
    }
    e.flags &= -3;
  }
  t & 4096 && (e.flags &= -4097);
}
function hc(e, t, n) {
  (k = e), L1(e);
}
function L1(e, t, n) {
  for (var r = (e.mode & 1) !== 0; k !== null; ) {
    var l = k,
      i = l.child;
    if (l.tag === 22 && r) {
      var o = l.memoizedState !== null || Lr;
      if (!o) {
        var a = l.alternate,
          u = (a !== null && a.memoizedState !== null) || oe;
        a = Lr;
        var f = oe;
        if (((Lr = o), (oe = u) && !f))
          for (k = l; k !== null; )
            (o = k),
              (u = o.child),
              o.tag === 22 && o.memoizedState !== null
                ? aa(l)
                : u !== null
                ? ((u.return = o), (k = u))
                : aa(l);
        for (; i !== null; ) (k = i), L1(i), (i = i.sibling);
        (k = l), (Lr = a), (oe = f);
      }
      oa(e);
    } else
      l.subtreeFlags & 8772 && i !== null ? ((i.return = l), (k = i)) : oa(e);
  }
}
function oa(e) {
  for (; k !== null; ) {
    var t = k;
    if (t.flags & 8772) {
      var n = t.alternate;
      try {
        if (t.flags & 8772)
          switch (t.tag) {
            case 0:
            case 11:
            case 15:
              oe || Cl(5, t);
              break;
            case 1:
              var r = t.stateNode;
              if (t.flags & 4 && !oe)
                if (n === null) r.componentDidMount();
                else {
                  var l =
                    t.elementType === t.type
                      ? n.memoizedProps
                      : ze(t.type, n.memoizedProps);
                  r.componentDidUpdate(
                    l,
                    n.memoizedState,
                    r.__reactInternalSnapshotBeforeUpdate
                  );
                }
              var i = t.updateQueue;
              i !== null && Hs(t, i, r);
              break;
            case 3:
              var o = t.updateQueue;
              if (o !== null) {
                if (((n = null), t.child !== null))
                  switch (t.child.tag) {
                    case 5:
                      n = t.child.stateNode;
                      break;
                    case 1:
                      n = t.child.stateNode;
                  }
                Hs(t, o, n);
              }
              break;
            case 5:
              var a = t.stateNode;
              if (n === null && t.flags & 4) {
                n = a;
                var u = t.memoizedProps;
                switch (t.type) {
                  case "button":
                  case "input":
                  case "select":
                  case "textarea":
                    u.autoFocus && n.focus();
                    break;
                  case "img":
                    u.src && (n.src = u.src);
                }
              }
              break;
            case 6:
              break;
            case 4:
              break;
            case 12:
              break;
            case 13:
              if (t.memoizedState === null) {
                var f = t.alternate;
                if (f !== null) {
                  var c = f.memoizedState;
                  if (c !== null) {
                    var h = c.dehydrated;
                    h !== null && Wn(h);
                  }
                }
              }
              break;
            case 19:
            case 17:
            case 21:
            case 22:
            case 23:
            case 25:
              break;
            default:
              throw Error(w(163));
          }
        oe || (t.flags & 512 && Ki(t));
      } catch (v) {
        Z(t, t.return, v);
      }
    }
    if (t === e) {
      k = null;
      break;
    }
    if (((n = t.sibling), n !== null)) {
      (n.return = t.return), (k = n);
      break;
    }
    k = t.return;
  }
}
function sa(e) {
  for (; k !== null; ) {
    var t = k;
    if (t === e) {
      k = null;
      break;
    }
    var n = t.sibling;
    if (n !== null) {
      (n.return = t.return), (k = n);
      break;
    }
    k = t.return;
  }
}
function aa(e) {
  for (; k !== null; ) {
    var t = k;
    try {
      switch (t.tag) {
        case 0:
        case 11:
        case 15:
          var n = t.return;
          try {
            Cl(4, t);
          } catch (u) {
            Z(t, n, u);
          }
          break;
        case 1:
          var r = t.stateNode;
          if (typeof r.componentDidMount == "function") {
            var l = t.return;
            try {
              r.componentDidMount();
            } catch (u) {
              Z(t, l, u);
            }
          }
          var i = t.return;
          try {
            Ki(t);
          } catch (u) {
            Z(t, i, u);
          }
          break;
        case 5:
          var o = t.return;
          try {
            Ki(t);
          } catch (u) {
            Z(t, o, u);
          }
      }
    } catch (u) {
      Z(t, t.return, u);
    }
    if (t === e) {
      k = null;
      break;
    }
    var a = t.sibling;
    if (a !== null) {
      (a.return = t.return), (k = a);
      break;
    }
    k = t.return;
  }
}
var vc = Math.ceil,
  ol = Je.ReactCurrentDispatcher,
  Vo = Je.ReactCurrentOwner,
  Le = Je.ReactCurrentBatchConfig,
  D = 0,
  ee = null,
  G = null,
  ne = 0,
  ge = 0,
  Yt = gt(0),
  Y = 0,
  nr = null,
  Rt = 0,
  wl = 0,
  Ho = 0,
  Bn = null,
  de = null,
  Zo = 0,
  un = 1 / 0,
  Ve = null,
  sl = !1,
  Ji = null,
  ft = null,
  _r = !1,
  lt = null,
  al = 0,
  In = 0,
  qi = null,
  Br = -1,
  Ir = 0;
function ue() {
  return D & 6 ? Q() : Br !== -1 ? Br : (Br = Q());
}
function dt(e) {
  return e.mode & 1
    ? D & 2 && ne !== 0
      ? ne & -ne
      : b0.transition !== null
      ? (Ir === 0 && (Ir = uu()), Ir)
      : ((e = O),
        e !== 0 || ((e = window.event), (e = e === void 0 ? 16 : vu(e.type))),
        e)
    : 1;
}
function De(e, t, n, r) {
  if (50 < In) throw ((In = 0), (qi = null), Error(w(185)));
  or(e, n, r),
    (!(D & 2) || e !== ee) &&
      (e === ee && (!(D & 2) && (wl |= n), Y === 4 && nt(e, ne)),
      ve(e, r),
      n === 1 && D === 0 && !(t.mode & 1) && ((un = Q() + 500), gl && xt()));
}
function ve(e, t) {
  var n = e.callbackNode;
  b3(e, t);
  var r = Wr(e, e === ee ? ne : 0);
  if (r === 0)
    n !== null && gs(n), (e.callbackNode = null), (e.callbackPriority = 0);
  else if (((t = r & -r), e.callbackPriority !== t)) {
    if ((n != null && gs(n), t === 1))
      e.tag === 0 ? q0(ua.bind(null, e)) : Ou(ua.bind(null, e)),
        K0(function () {
          !(D & 6) && xt();
        }),
        (n = null);
    else {
      switch (cu(r)) {
        case 1:
          n = vo;
          break;
        case 4:
          n = su;
          break;
        case 16:
          n = Zr;
          break;
        case 536870912:
          n = au;
          break;
        default:
          n = Zr;
      }
      n = D1(n, _1.bind(null, e));
    }
    (e.callbackPriority = t), (e.callbackNode = n);
  }
}
function _1(e, t) {
  if (((Br = -1), (Ir = 0), D & 6)) throw Error(w(327));
  var n = e.callbackNode;
  if (tn() && e.callbackNode !== n) return null;
  var r = Wr(e, e === ee ? ne : 0);
  if (r === 0) return null;
  if (r & 30 || r & e.expiredLanes || t) t = ul(e, r);
  else {
    t = r;
    var l = D;
    D |= 2;
    var i = P1();
    (ee !== e || ne !== t) && ((Ve = null), (un = Q() + 500), _t(e, t));
    do
      try {
        yc();
        break;
      } catch (a) {
        N1(e, a);
      }
    while (!0);
    Po(),
      (ol.current = i),
      (D = l),
      G !== null ? (t = 0) : ((ee = null), (ne = 0), (t = Y));
  }
  if (t !== 0) {
    if (
      (t === 2 && ((l = ki(e)), l !== 0 && ((r = l), (t = bi(e, l)))), t === 1)
    )
      throw ((n = nr), _t(e, 0), nt(e, r), ve(e, Q()), n);
    if (t === 6) nt(e, r);
    else {
      if (
        ((l = e.current.alternate),
        !(r & 30) &&
          !gc(l) &&
          ((t = ul(e, r)),
          t === 2 && ((i = ki(e)), i !== 0 && ((r = i), (t = bi(e, i)))),
          t === 1))
      )
        throw ((n = nr), _t(e, 0), nt(e, r), ve(e, Q()), n);
      switch (((e.finishedWork = l), (e.finishedLanes = r), t)) {
        case 0:
        case 1:
          throw Error(w(345));
        case 2:
          Et(e, de, Ve);
          break;
        case 3:
          if (
            (nt(e, r), (r & 130023424) === r && ((t = Zo + 500 - Q()), 10 < t))
          ) {
            if (Wr(e, 0) !== 0) break;
            if (((l = e.suspendedLanes), (l & r) !== r)) {
              ue(), (e.pingedLanes |= e.suspendedLanes & l);
              break;
            }
            e.timeoutHandle = Ri(Et.bind(null, e, de, Ve), t);
            break;
          }
          Et(e, de, Ve);
          break;
        case 4:
          if ((nt(e, r), (r & 4194240) === r)) break;
          for (t = e.eventTimes, l = -1; 0 < r; ) {
            var o = 31 - Re(r);
            (i = 1 << o), (o = t[o]), o > l && (l = o), (r &= ~i);
          }
          if (
            ((r = l),
            (r = Q() - r),
            (r =
              (120 > r
                ? 120
                : 480 > r
                ? 480
                : 1080 > r
                ? 1080
                : 1920 > r
                ? 1920
                : 3e3 > r
                ? 3e3
                : 4320 > r
                ? 4320
                : 1960 * vc(r / 1960)) - r),
            10 < r)
          ) {
            e.timeoutHandle = Ri(Et.bind(null, e, de, Ve), r);
            break;
          }
          Et(e, de, Ve);
          break;
        case 5:
          Et(e, de, Ve);
          break;
        default:
          throw Error(w(329));
      }
    }
  }
  return ve(e, Q()), e.callbackNode === n ? _1.bind(null, e) : null;
}
function bi(e, t) {
  var n = Bn;
  return (
    e.current.memoizedState.isDehydrated && (_t(e, t).flags |= 256),
    (e = ul(e, t)),
    e !== 2 && ((t = de), (de = n), t !== null && eo(t)),
    e
  );
}
function eo(e) {
  de === null ? (de = e) : de.push.apply(de, e);
}
function gc(e) {
  for (var t = e; ; ) {
    if (t.flags & 16384) {
      var n = t.updateQueue;
      if (n !== null && ((n = n.stores), n !== null))
        for (var r = 0; r < n.length; r++) {
          var l = n[r],
            i = l.getSnapshot;
          l = l.value;
          try {
            if (!Ue(i(), l)) return !1;
          } catch {
            return !1;
          }
        }
    }
    if (((n = t.child), t.subtreeFlags & 16384 && n !== null))
      (n.return = t), (t = n);
    else {
      if (t === e) break;
      for (; t.sibling === null; ) {
        if (t.return === null || t.return === e) return !0;
        t = t.return;
      }
      (t.sibling.return = t.return), (t = t.sibling);
    }
  }
  return !0;
}
function nt(e, t) {
  for (
    t &= ~Ho,
      t &= ~wl,
      e.suspendedLanes |= t,
      e.pingedLanes &= ~t,
      e = e.expirationTimes;
    0 < t;

  ) {
    var n = 31 - Re(t),
      r = 1 << n;
    (e[n] = -1), (t &= ~r);
  }
}
function ua(e) {
  if (D & 6) throw Error(w(327));
  tn();
  var t = Wr(e, 0);
  if (!(t & 1)) return ve(e, Q()), null;
  var n = ul(e, t);
  if (e.tag !== 0 && n === 2) {
    var r = ki(e);
    r !== 0 && ((t = r), (n = bi(e, r)));
  }
  if (n === 1) throw ((n = nr), _t(e, 0), nt(e, t), ve(e, Q()), n);
  if (n === 6) throw Error(w(345));
  return (
    (e.finishedWork = e.current.alternate),
    (e.finishedLanes = t),
    Et(e, de, Ve),
    ve(e, Q()),
    null
  );
}
function Wo(e, t) {
  var n = D;
  D |= 1;
  try {
    return e(t);
  } finally {
    (D = n), D === 0 && ((un = Q() + 500), gl && xt());
  }
}
function Dt(e) {
  lt !== null && lt.tag === 0 && !(D & 6) && tn();
  var t = D;
  D |= 1;
  var n = Le.transition,
    r = O;
  try {
    if (((Le.transition = null), (O = 1), e)) return e();
  } finally {
    (O = r), (Le.transition = n), (D = t), !(D & 6) && xt();
  }
}
function Qo() {
  (ge = Yt.current), B(Yt);
}
function _t(e, t) {
  (e.finishedWork = null), (e.finishedLanes = 0);
  var n = e.timeoutHandle;
  if ((n !== -1 && ((e.timeoutHandle = -1), G0(n)), G !== null))
    for (n = G.return; n !== null; ) {
      var r = n;
      switch ((Lo(r), r.tag)) {
        case 1:
          (r = r.type.childContextTypes), r != null && Xr();
          break;
        case 3:
          sn(), B(me), B(se), Oo();
          break;
        case 5:
          Do(r);
          break;
        case 4:
          sn();
          break;
        case 13:
          B(A);
          break;
        case 19:
          B(A);
          break;
        case 10:
          zo(r.type._context);
          break;
        case 22:
        case 23:
          Qo();
      }
      n = n.return;
    }
  if (
    ((ee = e),
    (G = e = pt(e.current, null)),
    (ne = ge = t),
    (Y = 0),
    (nr = null),
    (Ho = wl = Rt = 0),
    (de = Bn = null),
    kt !== null)
  ) {
    for (t = 0; t < kt.length; t++)
      if (((n = kt[t]), (r = n.interleaved), r !== null)) {
        n.interleaved = null;
        var l = r.next,
          i = n.pending;
        if (i !== null) {
          var o = i.next;
          (i.next = l), (r.next = o);
        }
        n.pending = r;
      }
    kt = null;
  }
  return e;
}
function N1(e, t) {
  do {
    var n = G;
    try {
      if ((Po(), (Or.current = il), ll)) {
        for (var r = V.memoizedState; r !== null; ) {
          var l = r.queue;
          l !== null && (l.pending = null), (r = r.next);
        }
        ll = !1;
      }
      if (
        ((Tt = 0),
        (b = K = V = null),
        (Un = !1),
        (bn = 0),
        (Vo.current = null),
        n === null || n.return === null)
      ) {
        (Y = 1), (nr = t), (G = null);
        break;
      }
      e: {
        var i = e,
          o = n.return,
          a = n,
          u = t;
        if (
          ((t = ne),
          (a.flags |= 32768),
          u !== null && typeof u == "object" && typeof u.then == "function")
        ) {
          var f = u,
            c = a,
            h = c.tag;
          if (!(c.mode & 1) && (h === 0 || h === 11 || h === 15)) {
            var v = c.alternate;
            v
              ? ((c.updateQueue = v.updateQueue),
                (c.memoizedState = v.memoizedState),
                (c.lanes = v.lanes))
              : ((c.updateQueue = null), (c.memoizedState = null));
          }
          var g = Xs(o);
          if (g !== null) {
            (g.flags &= -257),
              Js(g, o, a, i, t),
              g.mode & 1 && Ys(i, f, t),
              (t = g),
              (u = f);
            var x = t.updateQueue;
            if (x === null) {
              var C = new Set();
              C.add(u), (t.updateQueue = C);
            } else x.add(u);
            break e;
          } else {
            if (!(t & 1)) {
              Ys(i, f, t), Go();
              break e;
            }
            u = Error(w(426));
          }
        } else if ($ && a.mode & 1) {
          var j = Xs(o);
          if (j !== null) {
            !(j.flags & 65536) && (j.flags |= 256),
              Js(j, o, a, i, t),
              _o(an(u, a));
            break e;
          }
        }
        (i = u = an(u, a)),
          Y !== 4 && (Y = 2),
          Bn === null ? (Bn = [i]) : Bn.push(i),
          (i = o);
        do {
          switch (i.tag) {
            case 3:
              (i.flags |= 65536), (t &= -t), (i.lanes |= t);
              var p = f1(i, u, t);
              Vs(i, p);
              break e;
            case 1:
              a = u;
              var d = i.type,
                m = i.stateNode;
              if (
                !(i.flags & 128) &&
                (typeof d.getDerivedStateFromError == "function" ||
                  (m !== null &&
                    typeof m.componentDidCatch == "function" &&
                    (ft === null || !ft.has(m))))
              ) {
                (i.flags |= 65536), (t &= -t), (i.lanes |= t);
                var y = d1(i, a, t);
                Vs(i, y);
                break e;
              }
          }
          i = i.return;
        } while (i !== null);
      }
      M1(n);
    } catch (E) {
      (t = E), G === n && n !== null && (G = n = n.return);
      continue;
    }
    break;
  } while (!0);
}
function P1() {
  var e = ol.current;
  return (ol.current = il), e === null ? il : e;
}
function Go() {
  (Y === 0 || Y === 3 || Y === 2) && (Y = 4),
    ee === null || (!(Rt & 268435455) && !(wl & 268435455)) || nt(ee, ne);
}
function ul(e, t) {
  var n = D;
  D |= 2;
  var r = P1();
  (ee !== e || ne !== t) && ((Ve = null), _t(e, t));
  do
    try {
      xc();
      break;
    } catch (l) {
      N1(e, l);
    }
  while (!0);
  if ((Po(), (D = n), (ol.current = r), G !== null)) throw Error(w(261));
  return (ee = null), (ne = 0), Y;
}
function xc() {
  for (; G !== null; ) z1(G);
}
function yc() {
  for (; G !== null && !Z3(); ) z1(G);
}
function z1(e) {
  var t = R1(e.alternate, e, ge);
  (e.memoizedProps = e.pendingProps),
    t === null ? M1(e) : (G = t),
    (Vo.current = null);
}
function M1(e) {
  var t = e;
  do {
    var n = t.alternate;
    if (((e = t.return), t.flags & 32768)) {
      if (((n = dc(n, t)), n !== null)) {
        (n.flags &= 32767), (G = n);
        return;
      }
      if (e !== null)
        (e.flags |= 32768), (e.subtreeFlags = 0), (e.deletions = null);
      else {
        (Y = 6), (G = null);
        return;
      }
    } else if (((n = fc(n, t, ge)), n !== null)) {
      G = n;
      return;
    }
    if (((t = t.sibling), t !== null)) {
      G = t;
      return;
    }
    G = t = e;
  } while (t !== null);
  Y === 0 && (Y = 5);
}
function Et(e, t, n) {
  var r = O,
    l = Le.transition;
  try {
    (Le.transition = null), (O = 1), Cc(e, t, n, r);
  } finally {
    (Le.transition = l), (O = r);
  }
  return null;
}
function Cc(e, t, n, r) {
  do tn();
  while (lt !== null);
  if (D & 6) throw Error(w(327));
  n = e.finishedWork;
  var l = e.finishedLanes;
  if (n === null) return null;
  if (((e.finishedWork = null), (e.finishedLanes = 0), n === e.current))
    throw Error(w(177));
  (e.callbackNode = null), (e.callbackPriority = 0);
  var i = n.lanes | n.childLanes;
  if (
    (e0(e, i),
    e === ee && ((G = ee = null), (ne = 0)),
    (!(n.subtreeFlags & 2064) && !(n.flags & 2064)) ||
      _r ||
      ((_r = !0),
      D1(Zr, function () {
        return tn(), null;
      })),
    (i = (n.flags & 15990) !== 0),
    n.subtreeFlags & 15990 || i)
  ) {
    (i = Le.transition), (Le.transition = null);
    var o = O;
    O = 1;
    var a = D;
    (D |= 4),
      (Vo.current = null),
      mc(e, n),
      k1(n, e),
      $0(Mi),
      (Qr = !!zi),
      (Mi = zi = null),
      (e.current = n),
      hc(n),
      W3(),
      (D = a),
      (O = o),
      (Le.transition = i);
  } else e.current = n;
  if (
    (_r && ((_r = !1), (lt = e), (al = l)),
    (i = e.pendingLanes),
    i === 0 && (ft = null),
    K3(n.stateNode),
    ve(e, Q()),
    t !== null)
  )
    for (r = e.onRecoverableError, n = 0; n < t.length; n++)
      (l = t[n]), r(l.value, { componentStack: l.stack, digest: l.digest });
  if (sl) throw ((sl = !1), (e = Ji), (Ji = null), e);
  return (
    al & 1 && e.tag !== 0 && tn(),
    (i = e.pendingLanes),
    i & 1 ? (e === qi ? In++ : ((In = 0), (qi = e))) : (In = 0),
    xt(),
    null
  );
}
function tn() {
  if (lt !== null) {
    var e = cu(al),
      t = Le.transition,
      n = O;
    try {
      if (((Le.transition = null), (O = 16 > e ? 16 : e), lt === null))
        var r = !1;
      else {
        if (((e = lt), (lt = null), (al = 0), D & 6)) throw Error(w(331));
        var l = D;
        for (D |= 4, k = e.current; k !== null; ) {
          var i = k,
            o = i.child;
          if (k.flags & 16) {
            var a = i.deletions;
            if (a !== null) {
              for (var u = 0; u < a.length; u++) {
                var f = a[u];
                for (k = f; k !== null; ) {
                  var c = k;
                  switch (c.tag) {
                    case 0:
                    case 11:
                    case 15:
                      Fn(8, c, i);
                  }
                  var h = c.child;
                  if (h !== null) (h.return = c), (k = h);
                  else
                    for (; k !== null; ) {
                      c = k;
                      var v = c.sibling,
                        g = c.return;
                      if ((S1(c), c === f)) {
                        k = null;
                        break;
                      }
                      if (v !== null) {
                        (v.return = g), (k = v);
                        break;
                      }
                      k = g;
                    }
                }
              }
              var x = i.alternate;
              if (x !== null) {
                var C = x.child;
                if (C !== null) {
                  x.child = null;
                  do {
                    var j = C.sibling;
                    (C.sibling = null), (C = j);
                  } while (C !== null);
                }
              }
              k = i;
            }
          }
          if (i.subtreeFlags & 2064 && o !== null) (o.return = i), (k = o);
          else
            e: for (; k !== null; ) {
              if (((i = k), i.flags & 2048))
                switch (i.tag) {
                  case 0:
                  case 11:
                  case 15:
                    Fn(9, i, i.return);
                }
              var p = i.sibling;
              if (p !== null) {
                (p.return = i.return), (k = p);
                break e;
              }
              k = i.return;
            }
        }
        var d = e.current;
        for (k = d; k !== null; ) {
          o = k;
          var m = o.child;
          if (o.subtreeFlags & 2064 && m !== null) (m.return = o), (k = m);
          else
            e: for (o = d; k !== null; ) {
              if (((a = k), a.flags & 2048))
                try {
                  switch (a.tag) {
                    case 0:
                    case 11:
                    case 15:
                      Cl(9, a);
                  }
                } catch (E) {
                  Z(a, a.return, E);
                }
              if (a === o) {
                k = null;
                break e;
              }
              var y = a.sibling;
              if (y !== null) {
                (y.return = a.return), (k = y);
                break e;
              }
              k = a.return;
            }
        }
        if (
          ((D = l), xt(), $e && typeof $e.onPostCommitFiberRoot == "function")
        )
          try {
            $e.onPostCommitFiberRoot(dl, e);
          } catch {}
        r = !0;
      }
      return r;
    } finally {
      (O = n), (Le.transition = t);
    }
  }
  return !1;
}
function ca(e, t, n) {
  (t = an(n, t)),
    (t = f1(e, t, 1)),
    (e = ct(e, t, 1)),
    (t = ue()),
    e !== null && (or(e, 1, t), ve(e, t));
}
function Z(e, t, n) {
  if (e.tag === 3) ca(e, e, n);
  else
    for (; t !== null; ) {
      if (t.tag === 3) {
        ca(t, e, n);
        break;
      } else if (t.tag === 1) {
        var r = t.stateNode;
        if (
          typeof t.type.getDerivedStateFromError == "function" ||
          (typeof r.componentDidCatch == "function" &&
            (ft === null || !ft.has(r)))
        ) {
          (e = an(n, e)),
            (e = d1(t, e, 1)),
            (t = ct(t, e, 1)),
            (e = ue()),
            t !== null && (or(t, 1, e), ve(t, e));
          break;
        }
      }
      t = t.return;
    }
}
function wc(e, t, n) {
  var r = e.pingCache;
  r !== null && r.delete(t),
    (t = ue()),
    (e.pingedLanes |= e.suspendedLanes & n),
    ee === e &&
      (ne & n) === n &&
      (Y === 4 || (Y === 3 && (ne & 130023424) === ne && 500 > Q() - Zo)
        ? _t(e, 0)
        : (Ho |= n)),
    ve(e, t);
}
function T1(e, t) {
  t === 0 &&
    (e.mode & 1
      ? ((t = gr), (gr <<= 1), !(gr & 130023424) && (gr = 4194304))
      : (t = 1));
  var n = ue();
  (e = Ye(e, t)), e !== null && (or(e, t, n), ve(e, n));
}
function Sc(e) {
  var t = e.memoizedState,
    n = 0;
  t !== null && (n = t.retryLane), T1(e, n);
}
function Ec(e, t) {
  var n = 0;
  switch (e.tag) {
    case 13:
      var r = e.stateNode,
        l = e.memoizedState;
      l !== null && (n = l.retryLane);
      break;
    case 19:
      r = e.stateNode;
      break;
    default:
      throw Error(w(314));
  }
  r !== null && r.delete(t), T1(e, n);
}
var R1;
R1 = function (e, t, n) {
  if (e !== null)
    if (e.memoizedProps !== t.pendingProps || me.current) pe = !0;
    else {
      if (!(e.lanes & n) && !(t.flags & 128)) return (pe = !1), cc(e, t, n);
      pe = !!(e.flags & 131072);
    }
  else (pe = !1), $ && t.flags & 1048576 && Uu(t, br, t.index);
  switch (((t.lanes = 0), t.tag)) {
    case 2:
      var r = t.type;
      Fr(e, t), (e = t.pendingProps);
      var l = rn(t, se.current);
      en(t, n), (l = Fo(null, t, r, e, l, n));
      var i = Bo();
      return (
        (t.flags |= 1),
        typeof l == "object" &&
        l !== null &&
        typeof l.render == "function" &&
        l.$$typeof === void 0
          ? ((t.tag = 1),
            (t.memoizedState = null),
            (t.updateQueue = null),
            he(r) ? ((i = !0), Jr(t)) : (i = !1),
            (t.memoizedState =
              l.state !== null && l.state !== void 0 ? l.state : null),
            To(t),
            (l.updater = xl),
            (t.stateNode = l),
            (l._reactInternals = t),
            $i(t, r, e, n),
            (t = Hi(null, t, r, !0, i, n)))
          : ((t.tag = 0), $ && i && ko(t), ae(null, t, l, n), (t = t.child)),
        t
      );
    case 16:
      r = t.elementType;
      e: {
        switch (
          (Fr(e, t),
          (e = t.pendingProps),
          (l = r._init),
          (r = l(r._payload)),
          (t.type = r),
          (l = t.tag = kc(r)),
          (e = ze(r, e)),
          l)
        ) {
          case 0:
            t = Vi(null, t, r, e, n);
            break e;
          case 1:
            t = ea(null, t, r, e, n);
            break e;
          case 11:
            t = qs(null, t, r, e, n);
            break e;
          case 14:
            t = bs(null, t, r, ze(r.type, e), n);
            break e;
        }
        throw Error(w(306, r, ""));
      }
      return t;
    case 0:
      return (
        (r = t.type),
        (l = t.pendingProps),
        (l = t.elementType === r ? l : ze(r, l)),
        Vi(e, t, r, l, n)
      );
    case 1:
      return (
        (r = t.type),
        (l = t.pendingProps),
        (l = t.elementType === r ? l : ze(r, l)),
        ea(e, t, r, l, n)
      );
    case 3:
      e: {
        if ((v1(t), e === null)) throw Error(w(387));
        (r = t.pendingProps),
          (i = t.memoizedState),
          (l = i.element),
          $u(e, t),
          nl(t, r, null, n);
        var o = t.memoizedState;
        if (((r = o.element), i.isDehydrated))
          if (
            ((i = {
              element: r,
              isDehydrated: !1,
              cache: o.cache,
              pendingSuspenseBoundaries: o.pendingSuspenseBoundaries,
              transitions: o.transitions,
            }),
            (t.updateQueue.baseState = i),
            (t.memoizedState = i),
            t.flags & 256)
          ) {
            (l = an(Error(w(423)), t)), (t = ta(e, t, r, n, l));
            break e;
          } else if (r !== l) {
            (l = an(Error(w(424)), t)), (t = ta(e, t, r, n, l));
            break e;
          } else
            for (
              xe = ut(t.stateNode.containerInfo.firstChild),
                ye = t,
                $ = !0,
                Te = null,
                n = Zu(t, null, r, n),
                t.child = n;
              n;

            )
              (n.flags = (n.flags & -3) | 4096), (n = n.sibling);
        else {
          if ((ln(), r === l)) {
            t = Xe(e, t, n);
            break e;
          }
          ae(e, t, r, n);
        }
        t = t.child;
      }
      return t;
    case 5:
      return (
        Wu(t),
        e === null && Fi(t),
        (r = t.type),
        (l = t.pendingProps),
        (i = e !== null ? e.memoizedProps : null),
        (o = l.children),
        Ti(r, l) ? (o = null) : i !== null && Ti(r, i) && (t.flags |= 32),
        h1(e, t),
        ae(e, t, o, n),
        t.child
      );
    case 6:
      return e === null && Fi(t), null;
    case 13:
      return g1(e, t, n);
    case 4:
      return (
        Ro(t, t.stateNode.containerInfo),
        (r = t.pendingProps),
        e === null ? (t.child = on(t, null, r, n)) : ae(e, t, r, n),
        t.child
      );
    case 11:
      return (
        (r = t.type),
        (l = t.pendingProps),
        (l = t.elementType === r ? l : ze(r, l)),
        qs(e, t, r, l, n)
      );
    case 7:
      return ae(e, t, t.pendingProps, n), t.child;
    case 8:
      return ae(e, t, t.pendingProps.children, n), t.child;
    case 12:
      return ae(e, t, t.pendingProps.children, n), t.child;
    case 10:
      e: {
        if (
          ((r = t.type._context),
          (l = t.pendingProps),
          (i = t.memoizedProps),
          (o = l.value),
          U(el, r._currentValue),
          (r._currentValue = o),
          i !== null)
        )
          if (Ue(i.value, o)) {
            if (i.children === l.children && !me.current) {
              t = Xe(e, t, n);
              break e;
            }
          } else
            for (i = t.child, i !== null && (i.return = t); i !== null; ) {
              var a = i.dependencies;
              if (a !== null) {
                o = i.child;
                for (var u = a.firstContext; u !== null; ) {
                  if (u.context === r) {
                    if (i.tag === 1) {
                      (u = Qe(-1, n & -n)), (u.tag = 2);
                      var f = i.updateQueue;
                      if (f !== null) {
                        f = f.shared;
                        var c = f.pending;
                        c === null
                          ? (u.next = u)
                          : ((u.next = c.next), (c.next = u)),
                          (f.pending = u);
                      }
                    }
                    (i.lanes |= n),
                      (u = i.alternate),
                      u !== null && (u.lanes |= n),
                      Bi(i.return, n, t),
                      (a.lanes |= n);
                    break;
                  }
                  u = u.next;
                }
              } else if (i.tag === 10) o = i.type === t.type ? null : i.child;
              else if (i.tag === 18) {
                if (((o = i.return), o === null)) throw Error(w(341));
                (o.lanes |= n),
                  (a = o.alternate),
                  a !== null && (a.lanes |= n),
                  Bi(o, n, t),
                  (o = i.sibling);
              } else o = i.child;
              if (o !== null) o.return = i;
              else
                for (o = i; o !== null; ) {
                  if (o === t) {
                    o = null;
                    break;
                  }
                  if (((i = o.sibling), i !== null)) {
                    (i.return = o.return), (o = i);
                    break;
                  }
                  o = o.return;
                }
              i = o;
            }
        ae(e, t, l.children, n), (t = t.child);
      }
      return t;
    case 9:
      return (
        (l = t.type),
        (r = t.pendingProps.children),
        en(t, n),
        (l = _e(l)),
        (r = r(l)),
        (t.flags |= 1),
        ae(e, t, r, n),
        t.child
      );
    case 14:
      return (
        (r = t.type),
        (l = ze(r, t.pendingProps)),
        (l = ze(r.type, l)),
        bs(e, t, r, l, n)
      );
    case 15:
      return p1(e, t, t.type, t.pendingProps, n);
    case 17:
      return (
        (r = t.type),
        (l = t.pendingProps),
        (l = t.elementType === r ? l : ze(r, l)),
        Fr(e, t),
        (t.tag = 1),
        he(r) ? ((e = !0), Jr(t)) : (e = !1),
        en(t, n),
        Vu(t, r, l),
        $i(t, r, l, n),
        Hi(null, t, r, !0, e, n)
      );
    case 19:
      return x1(e, t, n);
    case 22:
      return m1(e, t, n);
  }
  throw Error(w(156, t.tag));
};
function D1(e, t) {
  return ou(e, t);
}
function jc(e, t, n, r) {
  (this.tag = e),
    (this.key = n),
    (this.sibling =
      this.child =
      this.return =
      this.stateNode =
      this.type =
      this.elementType =
        null),
    (this.index = 0),
    (this.ref = null),
    (this.pendingProps = t),
    (this.dependencies =
      this.memoizedState =
      this.updateQueue =
      this.memoizedProps =
        null),
    (this.mode = r),
    (this.subtreeFlags = this.flags = 0),
    (this.deletions = null),
    (this.childLanes = this.lanes = 0),
    (this.alternate = null);
}
function ke(e, t, n, r) {
  return new jc(e, t, n, r);
}
function Ko(e) {
  return (e = e.prototype), !(!e || !e.isReactComponent);
}
function kc(e) {
  if (typeof e == "function") return Ko(e) ? 1 : 0;
  if (e != null) {
    if (((e = e.$$typeof), e === po)) return 11;
    if (e === mo) return 14;
  }
  return 2;
}
function pt(e, t) {
  var n = e.alternate;
  return (
    n === null
      ? ((n = ke(e.tag, t, e.key, e.mode)),
        (n.elementType = e.elementType),
        (n.type = e.type),
        (n.stateNode = e.stateNode),
        (n.alternate = e),
        (e.alternate = n))
      : ((n.pendingProps = t),
        (n.type = e.type),
        (n.flags = 0),
        (n.subtreeFlags = 0),
        (n.deletions = null)),
    (n.flags = e.flags & 14680064),
    (n.childLanes = e.childLanes),
    (n.lanes = e.lanes),
    (n.child = e.child),
    (n.memoizedProps = e.memoizedProps),
    (n.memoizedState = e.memoizedState),
    (n.updateQueue = e.updateQueue),
    (t = e.dependencies),
    (n.dependencies =
      t === null ? null : { lanes: t.lanes, firstContext: t.firstContext }),
    (n.sibling = e.sibling),
    (n.index = e.index),
    (n.ref = e.ref),
    n
  );
}
function $r(e, t, n, r, l, i) {
  var o = 2;
  if (((r = e), typeof e == "function")) Ko(e) && (o = 1);
  else if (typeof e == "string") o = 5;
  else
    e: switch (e) {
      case It:
        return Nt(n.children, l, i, t);
      case fo:
        (o = 8), (l |= 8);
        break;
      case ci:
        return (
          (e = ke(12, n, t, l | 2)), (e.elementType = ci), (e.lanes = i), e
        );
      case fi:
        return (e = ke(13, n, t, l)), (e.elementType = fi), (e.lanes = i), e;
      case di:
        return (e = ke(19, n, t, l)), (e.elementType = di), (e.lanes = i), e;
      case Ha:
        return Sl(n, l, i, t);
      default:
        if (typeof e == "object" && e !== null)
          switch (e.$$typeof) {
            case Aa:
              o = 10;
              break e;
            case Va:
              o = 9;
              break e;
            case po:
              o = 11;
              break e;
            case mo:
              o = 14;
              break e;
            case be:
              (o = 16), (r = null);
              break e;
          }
        throw Error(w(130, e == null ? e : typeof e, ""));
    }
  return (
    (t = ke(o, n, t, l)), (t.elementType = e), (t.type = r), (t.lanes = i), t
  );
}
function Nt(e, t, n, r) {
  return (e = ke(7, e, r, t)), (e.lanes = n), e;
}
function Sl(e, t, n, r) {
  return (
    (e = ke(22, e, r, t)),
    (e.elementType = Ha),
    (e.lanes = n),
    (e.stateNode = { isHidden: !1 }),
    e
  );
}
function li(e, t, n) {
  return (e = ke(6, e, null, t)), (e.lanes = n), e;
}
function ii(e, t, n) {
  return (
    (t = ke(4, e.children !== null ? e.children : [], e.key, t)),
    (t.lanes = n),
    (t.stateNode = {
      containerInfo: e.containerInfo,
      pendingChildren: null,
      implementation: e.implementation,
    }),
    t
  );
}
function Lc(e, t, n, r, l) {
  (this.tag = t),
    (this.containerInfo = e),
    (this.finishedWork =
      this.pingCache =
      this.current =
      this.pendingChildren =
        null),
    (this.timeoutHandle = -1),
    (this.callbackNode = this.pendingContext = this.context = null),
    (this.callbackPriority = 0),
    (this.eventTimes = Il(0)),
    (this.expirationTimes = Il(-1)),
    (this.entangledLanes =
      this.finishedLanes =
      this.mutableReadLanes =
      this.expiredLanes =
      this.pingedLanes =
      this.suspendedLanes =
      this.pendingLanes =
        0),
    (this.entanglements = Il(0)),
    (this.identifierPrefix = r),
    (this.onRecoverableError = l),
    (this.mutableSourceEagerHydrationData = null);
}
function Yo(e, t, n, r, l, i, o, a, u) {
  return (
    (e = new Lc(e, t, n, a, u)),
    t === 1 ? ((t = 1), i === !0 && (t |= 8)) : (t = 0),
    (i = ke(3, null, null, t)),
    (e.current = i),
    (i.stateNode = e),
    (i.memoizedState = {
      element: r,
      isDehydrated: n,
      cache: null,
      transitions: null,
      pendingSuspenseBoundaries: null,
    }),
    To(i),
    e
  );
}
function _c(e, t, n) {
  var r = 3 < arguments.length && arguments[3] !== void 0 ? arguments[3] : null;
  return {
    $$typeof: Bt,
    key: r == null ? null : "" + r,
    children: e,
    containerInfo: t,
    implementation: n,
  };
}
function O1(e) {
  if (!e) return ht;
  e = e._reactInternals;
  e: {
    if (Ut(e) !== e || e.tag !== 1) throw Error(w(170));
    var t = e;
    do {
      switch (t.tag) {
        case 3:
          t = t.stateNode.context;
          break e;
        case 1:
          if (he(t.type)) {
            t = t.stateNode.__reactInternalMemoizedMergedChildContext;
            break e;
          }
      }
      t = t.return;
    } while (t !== null);
    throw Error(w(171));
  }
  if (e.tag === 1) {
    var n = e.type;
    if (he(n)) return Du(e, n, t);
  }
  return t;
}
function U1(e, t, n, r, l, i, o, a, u) {
  return (
    (e = Yo(n, r, !0, e, l, i, o, a, u)),
    (e.context = O1(null)),
    (n = e.current),
    (r = ue()),
    (l = dt(n)),
    (i = Qe(r, l)),
    (i.callback = t ?? null),
    ct(n, i, l),
    (e.current.lanes = l),
    or(e, l, r),
    ve(e, r),
    e
  );
}
function El(e, t, n, r) {
  var l = t.current,
    i = ue(),
    o = dt(l);
  return (
    (n = O1(n)),
    t.context === null ? (t.context = n) : (t.pendingContext = n),
    (t = Qe(i, o)),
    (t.payload = { element: e }),
    (r = r === void 0 ? null : r),
    r !== null && (t.callback = r),
    (e = ct(l, t, o)),
    e !== null && (De(e, l, o, i), Dr(e, l, o)),
    o
  );
}
function cl(e) {
  if (((e = e.current), !e.child)) return null;
  switch (e.child.tag) {
    case 5:
      return e.child.stateNode;
    default:
      return e.child.stateNode;
  }
}
function fa(e, t) {
  if (((e = e.memoizedState), e !== null && e.dehydrated !== null)) {
    var n = e.retryLane;
    e.retryLane = n !== 0 && n < t ? n : t;
  }
}
function Xo(e, t) {
  fa(e, t), (e = e.alternate) && fa(e, t);
}
function Nc() {
  return null;
}
var F1 =
  typeof reportError == "function"
    ? reportError
    : function (e) {
        console.error(e);
      };
function Jo(e) {
  this._internalRoot = e;
}
jl.prototype.render = Jo.prototype.render = function (e) {
  var t = this._internalRoot;
  if (t === null) throw Error(w(409));
  El(e, t, null, null);
};
jl.prototype.unmount = Jo.prototype.unmount = function () {
  var e = this._internalRoot;
  if (e !== null) {
    this._internalRoot = null;
    var t = e.containerInfo;
    Dt(function () {
      El(null, e, null, null);
    }),
      (t[Ke] = null);
  }
};
function jl(e) {
  this._internalRoot = e;
}
jl.prototype.unstable_scheduleHydration = function (e) {
  if (e) {
    var t = pu();
    e = { blockedOn: null, target: e, priority: t };
    for (var n = 0; n < tt.length && t !== 0 && t < tt[n].priority; n++);
    tt.splice(n, 0, e), n === 0 && hu(e);
  }
};
function qo(e) {
  return !(!e || (e.nodeType !== 1 && e.nodeType !== 9 && e.nodeType !== 11));
}
function kl(e) {
  return !(
    !e ||
    (e.nodeType !== 1 &&
      e.nodeType !== 9 &&
      e.nodeType !== 11 &&
      (e.nodeType !== 8 || e.nodeValue !== " react-mount-point-unstable "))
  );
}
function da() {}
function Pc(e, t, n, r, l) {
  if (l) {
    if (typeof r == "function") {
      var i = r;
      r = function () {
        var f = cl(o);
        i.call(f);
      };
    }
    var o = U1(t, r, e, 0, null, !1, !1, "", da);
    return (
      (e._reactRootContainer = o),
      (e[Ke] = o.current),
      Kn(e.nodeType === 8 ? e.parentNode : e),
      Dt(),
      o
    );
  }
  for (; (l = e.lastChild); ) e.removeChild(l);
  if (typeof r == "function") {
    var a = r;
    r = function () {
      var f = cl(u);
      a.call(f);
    };
  }
  var u = Yo(e, 0, !1, null, null, !1, !1, "", da);
  return (
    (e._reactRootContainer = u),
    (e[Ke] = u.current),
    Kn(e.nodeType === 8 ? e.parentNode : e),
    Dt(function () {
      El(t, u, n, r);
    }),
    u
  );
}
function Ll(e, t, n, r, l) {
  var i = n._reactRootContainer;
  if (i) {
    var o = i;
    if (typeof l == "function") {
      var a = l;
      l = function () {
        var u = cl(o);
        a.call(u);
      };
    }
    El(t, o, e, l);
  } else o = Pc(n, t, e, l, r);
  return cl(o);
}
fu = function (e) {
  switch (e.tag) {
    case 3:
      var t = e.stateNode;
      if (t.current.memoizedState.isDehydrated) {
        var n = _n(t.pendingLanes);
        n !== 0 &&
          (go(t, n | 1), ve(t, Q()), !(D & 6) && ((un = Q() + 500), xt()));
      }
      break;
    case 13:
      Dt(function () {
        var r = Ye(e, 1);
        if (r !== null) {
          var l = ue();
          De(r, e, 1, l);
        }
      }),
        Xo(e, 1);
  }
};
xo = function (e) {
  if (e.tag === 13) {
    var t = Ye(e, 134217728);
    if (t !== null) {
      var n = ue();
      De(t, e, 134217728, n);
    }
    Xo(e, 134217728);
  }
};
du = function (e) {
  if (e.tag === 13) {
    var t = dt(e),
      n = Ye(e, t);
    if (n !== null) {
      var r = ue();
      De(n, e, t, r);
    }
    Xo(e, t);
  }
};
pu = function () {
  return O;
};
mu = function (e, t) {
  var n = O;
  try {
    return (O = e), t();
  } finally {
    O = n;
  }
};
Si = function (e, t, n) {
  switch (t) {
    case "input":
      if ((hi(e, n), (t = n.name), n.type === "radio" && t != null)) {
        for (n = e; n.parentNode; ) n = n.parentNode;
        for (
          n = n.querySelectorAll(
            "input[name=" + JSON.stringify("" + t) + '][type="radio"]'
          ),
            t = 0;
          t < n.length;
          t++
        ) {
          var r = n[t];
          if (r !== e && r.form === e.form) {
            var l = vl(r);
            if (!l) throw Error(w(90));
            Wa(r), hi(r, l);
          }
        }
      }
      break;
    case "textarea":
      Ga(e, n);
      break;
    case "select":
      (t = n.value), t != null && Xt(e, !!n.multiple, t, !1);
  }
};
eu = Wo;
tu = Dt;
var zc = { usingClientEntryPoint: !1, Events: [ar, Ht, vl, qa, ba, Wo] },
  jn = {
    findFiberByHostInstance: jt,
    bundleType: 0,
    version: "18.2.0",
    rendererPackageName: "react-dom",
  },
  Mc = {
    bundleType: jn.bundleType,
    version: jn.version,
    rendererPackageName: jn.rendererPackageName,
    rendererConfig: jn.rendererConfig,
    overrideHookState: null,
    overrideHookStateDeletePath: null,
    overrideHookStateRenamePath: null,
    overrideProps: null,
    overridePropsDeletePath: null,
    overridePropsRenamePath: null,
    setErrorHandler: null,
    setSuspenseHandler: null,
    scheduleUpdate: null,
    currentDispatcherRef: Je.ReactCurrentDispatcher,
    findHostInstanceByFiber: function (e) {
      return (e = lu(e)), e === null ? null : e.stateNode;
    },
    findFiberByHostInstance: jn.findFiberByHostInstance || Nc,
    findHostInstancesForRefresh: null,
    scheduleRefresh: null,
    scheduleRoot: null,
    setRefreshHandler: null,
    getCurrentFiber: null,
    reconcilerVersion: "18.2.0-next-9e3b772b8-20220608",
  };
if (typeof __REACT_DEVTOOLS_GLOBAL_HOOK__ < "u") {
  var Nr = __REACT_DEVTOOLS_GLOBAL_HOOK__;
  if (!Nr.isDisabled && Nr.supportsFiber)
    try {
      (dl = Nr.inject(Mc)), ($e = Nr);
    } catch {}
}
we.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = zc;
we.createPortal = function (e, t) {
  var n = 2 < arguments.length && arguments[2] !== void 0 ? arguments[2] : null;
  if (!qo(t)) throw Error(w(200));
  return _c(e, t, null, n);
};
we.createRoot = function (e, t) {
  if (!qo(e)) throw Error(w(299));
  var n = !1,
    r = "",
    l = F1;
  return (
    t != null &&
      (t.unstable_strictMode === !0 && (n = !0),
      t.identifierPrefix !== void 0 && (r = t.identifierPrefix),
      t.onRecoverableError !== void 0 && (l = t.onRecoverableError)),
    (t = Yo(e, 1, !1, null, null, n, !1, r, l)),
    (e[Ke] = t.current),
    Kn(e.nodeType === 8 ? e.parentNode : e),
    new Jo(t)
  );
};
we.findDOMNode = function (e) {
  if (e == null) return null;
  if (e.nodeType === 1) return e;
  var t = e._reactInternals;
  if (t === void 0)
    throw typeof e.render == "function"
      ? Error(w(188))
      : ((e = Object.keys(e).join(",")), Error(w(268, e)));
  return (e = lu(t)), (e = e === null ? null : e.stateNode), e;
};
we.flushSync = function (e) {
  return Dt(e);
};
we.hydrate = function (e, t, n) {
  if (!kl(t)) throw Error(w(200));
  return Ll(null, e, t, !0, n);
};
we.hydrateRoot = function (e, t, n) {
  if (!qo(e)) throw Error(w(405));
  var r = (n != null && n.hydratedSources) || null,
    l = !1,
    i = "",
    o = F1;
  if (
    (n != null &&
      (n.unstable_strictMode === !0 && (l = !0),
      n.identifierPrefix !== void 0 && (i = n.identifierPrefix),
      n.onRecoverableError !== void 0 && (o = n.onRecoverableError)),
    (t = U1(t, null, e, 1, n ?? null, l, !1, i, o)),
    (e[Ke] = t.current),
    Kn(e),
    r)
  )
    for (e = 0; e < r.length; e++)
      (n = r[e]),
        (l = n._getVersion),
        (l = l(n._source)),
        t.mutableSourceEagerHydrationData == null
          ? (t.mutableSourceEagerHydrationData = [n, l])
          : t.mutableSourceEagerHydrationData.push(n, l);
  return new jl(t);
};
we.render = function (e, t, n) {
  if (!kl(t)) throw Error(w(200));
  return Ll(null, e, t, !1, n);
};
we.unmountComponentAtNode = function (e) {
  if (!kl(e)) throw Error(w(40));
  return e._reactRootContainer
    ? (Dt(function () {
        Ll(null, null, e, !1, function () {
          (e._reactRootContainer = null), (e[Ke] = null);
        });
      }),
      !0)
    : !1;
};
we.unstable_batchedUpdates = Wo;
we.unstable_renderSubtreeIntoContainer = function (e, t, n, r) {
  if (!kl(n)) throw Error(w(200));
  if (e == null || e._reactInternals === void 0) throw Error(w(38));
  return Ll(e, t, n, !1, r);
};
we.version = "18.2.0-next-9e3b772b8-20220608";
function B1() {
  if (
    !(
      typeof __REACT_DEVTOOLS_GLOBAL_HOOK__ > "u" ||
      typeof __REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE != "function"
    )
  )
    try {
      __REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE(B1);
    } catch (e) {
      console.error(e);
    }
}
B1(), (Ua.exports = we);
var Tc = Ua.exports,
  pa = Tc;
(ai.createRoot = pa.createRoot), (ai.hydrateRoot = pa.hydrateRoot);
const I1 = () => !window.invokeNative,
  Rc = () => {},
  bo = (e, t) => {
    const n = S.useRef(Rc);
    S.useEffect(() => {
      n.current = t;
    }, [t]),
      S.useEffect(() => {
        const r = (l) => {
          const { action: i, data: o } = l.data;
          n.current && i === e && n.current(o);
        };
        return (
          window.addEventListener("message", r),
          () => window.removeEventListener("message", r)
        );
      }, [e]);
  };
async function Oe(e, t, n) {
  const r = {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(t),
  };
  if (I1() && n) return n;
  const l = window.GetParentResourceName
    ? window.GetParentResourceName()
    : "react-app";
  return await (await fetch(`https://${l}/${e}`, r)).json();
}
/**
 * @remix-run/router v1.16.0
 *
 * Copyright (c) Remix Software Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.md file in the root directory of this source tree.
 *
 * @license MIT
 */ function rr() {
  return (
    (rr = Object.assign
      ? Object.assign.bind()
      : function (e) {
          for (var t = 1; t < arguments.length; t++) {
            var n = arguments[t];
            for (var r in n)
              Object.prototype.hasOwnProperty.call(n, r) && (e[r] = n[r]);
          }
          return e;
        }),
    rr.apply(this, arguments)
  );
}
var it;
(function (e) {
  (e.Pop = "POP"), (e.Push = "PUSH"), (e.Replace = "REPLACE");
})(it || (it = {}));
const ma = "popstate";
function Dc(e) {
  e === void 0 && (e = {});
  function t(r, l) {
    let { pathname: i, search: o, hash: a } = r.location;
    return to(
      "",
      { pathname: i, search: o, hash: a },
      (l.state && l.state.usr) || null,
      (l.state && l.state.key) || "default"
    );
  }
  function n(r, l) {
    return typeof l == "string" ? l : A1(l);
  }
  return Uc(t, n, null, e);
}
function X(e, t) {
  if (e === !1 || e === null || typeof e > "u") throw new Error(t);
}
function $1(e, t) {
  if (!e) {
    typeof console < "u" && console.warn(t);
    try {
      throw new Error(t);
    } catch {}
  }
}
function Oc() {
  return Math.random().toString(36).substr(2, 8);
}
function ha(e, t) {
  return { usr: e.state, key: e.key, idx: t };
}
function to(e, t, n, r) {
  return (
    n === void 0 && (n = null),
    rr(
      { pathname: typeof e == "string" ? e : e.pathname, search: "", hash: "" },
      typeof t == "string" ? mn(t) : t,
      { state: n, key: (t && t.key) || r || Oc() }
    )
  );
}
function A1(e) {
  let { pathname: t = "/", search: n = "", hash: r = "" } = e;
  return (
    n && n !== "?" && (t += n.charAt(0) === "?" ? n : "?" + n),
    r && r !== "#" && (t += r.charAt(0) === "#" ? r : "#" + r),
    t
  );
}
function mn(e) {
  let t = {};
  if (e) {
    let n = e.indexOf("#");
    n >= 0 && ((t.hash = e.substr(n)), (e = e.substr(0, n)));
    let r = e.indexOf("?");
    r >= 0 && ((t.search = e.substr(r)), (e = e.substr(0, r))),
      e && (t.pathname = e);
  }
  return t;
}
function Uc(e, t, n, r) {
  r === void 0 && (r = {});
  let { window: l = document.defaultView, v5Compat: i = !1 } = r,
    o = l.history,
    a = it.Pop,
    u = null,
    f = c();
  f == null && ((f = 0), o.replaceState(rr({}, o.state, { idx: f }), ""));
  function c() {
    return (o.state || { idx: null }).idx;
  }
  function h() {
    a = it.Pop;
    let j = c(),
      p = j == null ? null : j - f;
    (f = j), u && u({ action: a, location: C.location, delta: p });
  }
  function v(j, p) {
    a = it.Push;
    let d = to(C.location, j, p);
    f = c() + 1;
    let m = ha(d, f),
      y = C.createHref(d);
    try {
      o.pushState(m, "", y);
    } catch (E) {
      if (E instanceof DOMException && E.name === "DataCloneError") throw E;
      l.location.assign(y);
    }
    i && u && u({ action: a, location: C.location, delta: 1 });
  }
  function g(j, p) {
    a = it.Replace;
    let d = to(C.location, j, p);
    f = c();
    let m = ha(d, f),
      y = C.createHref(d);
    o.replaceState(m, "", y),
      i && u && u({ action: a, location: C.location, delta: 0 });
  }
  function x(j) {
    let p = l.location.origin !== "null" ? l.location.origin : l.location.href,
      d = typeof j == "string" ? j : A1(j);
    return (
      (d = d.replace(/ $/, "%20")),
      X(
        p,
        "No window.location.(origin|href) available to create URL for href: " +
          d
      ),
      new URL(d, p)
    );
  }
  let C = {
    get action() {
      return a;
    },
    get location() {
      return e(l, o);
    },
    listen(j) {
      if (u) throw new Error("A history only accepts one active listener");
      return (
        l.addEventListener(ma, h),
        (u = j),
        () => {
          l.removeEventListener(ma, h), (u = null);
        }
      );
    },
    createHref(j) {
      return t(l, j);
    },
    createURL: x,
    encodeLocation(j) {
      let p = x(j);
      return { pathname: p.pathname, search: p.search, hash: p.hash };
    },
    push: v,
    replace: g,
    go(j) {
      return o.go(j);
    },
  };
  return C;
}
var va;
(function (e) {
  (e.data = "data"),
    (e.deferred = "deferred"),
    (e.redirect = "redirect"),
    (e.error = "error");
})(va || (va = {}));
function Fc(e, t, n) {
  n === void 0 && (n = "/");
  let r = typeof t == "string" ? mn(t) : t,
    l = Z1(r.pathname || "/", n);
  if (l == null) return null;
  let i = V1(e);
  Bc(i);
  let o = null;
  for (let a = 0; o == null && a < i.length; ++a) {
    let u = Xc(l);
    o = Gc(i[a], u);
  }
  return o;
}
function V1(e, t, n, r) {
  t === void 0 && (t = []), n === void 0 && (n = []), r === void 0 && (r = "");
  let l = (i, o, a) => {
    let u = {
      relativePath: a === void 0 ? i.path || "" : a,
      caseSensitive: i.caseSensitive === !0,
      childrenIndex: o,
      route: i,
    };
    u.relativePath.startsWith("/") &&
      (X(
        u.relativePath.startsWith(r),
        'Absolute route path "' +
          u.relativePath +
          '" nested under path ' +
          ('"' + r + '" is not valid. An absolute child route path ') +
          "must start with the combined path of all its parent routes."
      ),
      (u.relativePath = u.relativePath.slice(r.length)));
    let f = Pt([r, u.relativePath]),
      c = n.concat(u);
    i.children &&
      i.children.length > 0 &&
      (X(
        i.index !== !0,
        "Index routes must not have child routes. Please remove " +
          ('all child routes from route path "' + f + '".')
      ),
      V1(i.children, t, c, f)),
      !(i.path == null && !i.index) &&
        t.push({ path: f, score: Wc(f, i.index), routesMeta: c });
  };
  return (
    e.forEach((i, o) => {
      var a;
      if (i.path === "" || !((a = i.path) != null && a.includes("?"))) l(i, o);
      else for (let u of H1(i.path)) l(i, o, u);
    }),
    t
  );
}
function H1(e) {
  let t = e.split("/");
  if (t.length === 0) return [];
  let [n, ...r] = t,
    l = n.endsWith("?"),
    i = n.replace(/\?$/, "");
  if (r.length === 0) return l ? [i, ""] : [i];
  let o = H1(r.join("/")),
    a = [];
  return (
    a.push(...o.map((u) => (u === "" ? i : [i, u].join("/")))),
    l && a.push(...o),
    a.map((u) => (e.startsWith("/") && u === "" ? "/" : u))
  );
}
function Bc(e) {
  e.sort((t, n) =>
    t.score !== n.score
      ? n.score - t.score
      : Qc(
          t.routesMeta.map((r) => r.childrenIndex),
          n.routesMeta.map((r) => r.childrenIndex)
        )
  );
}
const Ic = /^:[\w-]+$/,
  $c = 3,
  Ac = 2,
  Vc = 1,
  Hc = 10,
  Zc = -2,
  ga = (e) => e === "*";
function Wc(e, t) {
  let n = e.split("/"),
    r = n.length;
  return (
    n.some(ga) && (r += Zc),
    t && (r += Ac),
    n
      .filter((l) => !ga(l))
      .reduce((l, i) => l + (Ic.test(i) ? $c : i === "" ? Vc : Hc), r)
  );
}
function Qc(e, t) {
  return e.length === t.length && e.slice(0, -1).every((r, l) => r === t[l])
    ? e[e.length - 1] - t[t.length - 1]
    : 0;
}
function Gc(e, t) {
  let { routesMeta: n } = e,
    r = {},
    l = "/",
    i = [];
  for (let o = 0; o < n.length; ++o) {
    let a = n[o],
      u = o === n.length - 1,
      f = l === "/" ? t : t.slice(l.length) || "/",
      c = Kc(
        { path: a.relativePath, caseSensitive: a.caseSensitive, end: u },
        f
      );
    if (!c) return null;
    Object.assign(r, c.params);
    let h = a.route;
    i.push({
      params: r,
      pathname: Pt([l, c.pathname]),
      pathnameBase: n2(Pt([l, c.pathnameBase])),
      route: h,
    }),
      c.pathnameBase !== "/" && (l = Pt([l, c.pathnameBase]));
  }
  return i;
}
function Kc(e, t) {
  typeof e == "string" && (e = { path: e, caseSensitive: !1, end: !0 });
  let [n, r] = Yc(e.path, e.caseSensitive, e.end),
    l = t.match(n);
  if (!l) return null;
  let i = l[0],
    o = i.replace(/(.)\/+$/, "$1"),
    a = l.slice(1);
  return {
    params: r.reduce((f, c, h) => {
      let { paramName: v, isOptional: g } = c;
      if (v === "*") {
        let C = a[h] || "";
        o = i.slice(0, i.length - C.length).replace(/(.)\/+$/, "$1");
      }
      const x = a[h];
      return (
        g && !x ? (f[v] = void 0) : (f[v] = (x || "").replace(/%2F/g, "/")), f
      );
    }, {}),
    pathname: i,
    pathnameBase: o,
    pattern: e,
  };
}
function Yc(e, t, n) {
  t === void 0 && (t = !1),
    n === void 0 && (n = !0),
    $1(
      e === "*" || !e.endsWith("*") || e.endsWith("/*"),
      'Route path "' +
        e +
        '" will be treated as if it were ' +
        ('"' + e.replace(/\*$/, "/*") + '" because the `*` character must ') +
        "always follow a `/` in the pattern. To get rid of this warning, " +
        ('please change the route path to "' + e.replace(/\*$/, "/*") + '".')
    );
  let r = [],
    l =
      "^" +
      e
        .replace(/\/*\*?$/, "")
        .replace(/^\/*/, "/")
        .replace(/[\\.*+^${}|()[\]]/g, "\\$&")
        .replace(
          /\/:([\w-]+)(\?)?/g,
          (o, a, u) => (
            r.push({ paramName: a, isOptional: u != null }),
            u ? "/?([^\\/]+)?" : "/([^\\/]+)"
          )
        );
  return (
    e.endsWith("*")
      ? (r.push({ paramName: "*" }),
        (l += e === "*" || e === "/*" ? "(.*)$" : "(?:\\/(.+)|\\/*)$"))
      : n
      ? (l += "\\/*$")
      : e !== "" && e !== "/" && (l += "(?:(?=\\/|$))"),
    [new RegExp(l, t ? void 0 : "i"), r]
  );
}
function Xc(e) {
  try {
    return e
      .split("/")
      .map((t) => decodeURIComponent(t).replace(/\//g, "%2F"))
      .join("/");
  } catch (t) {
    return (
      $1(
        !1,
        'The URL path "' +
          e +
          '" could not be decoded because it is is a malformed URL segment. This is probably due to a bad percent ' +
          ("encoding (" + t + ").")
      ),
      e
    );
  }
}
function Z1(e, t) {
  if (t === "/") return e;
  if (!e.toLowerCase().startsWith(t.toLowerCase())) return null;
  let n = t.endsWith("/") ? t.length - 1 : t.length,
    r = e.charAt(n);
  return r && r !== "/" ? null : e.slice(n) || "/";
}
function Jc(e, t) {
  t === void 0 && (t = "/");
  let {
    pathname: n,
    search: r = "",
    hash: l = "",
  } = typeof e == "string" ? mn(e) : e;
  return {
    pathname: n ? (n.startsWith("/") ? n : qc(n, t)) : t,
    search: r2(r),
    hash: l2(l),
  };
}
function qc(e, t) {
  let n = t.replace(/\/+$/, "").split("/");
  return (
    e.split("/").forEach((l) => {
      l === ".." ? n.length > 1 && n.pop() : l !== "." && n.push(l);
    }),
    n.length > 1 ? n.join("/") : "/"
  );
}
function oi(e, t, n, r) {
  return (
    "Cannot include a '" +
    e +
    "' character in a manually specified " +
    ("`to." +
      t +
      "` field [" +
      JSON.stringify(r) +
      "].  Please separate it out to the ") +
    ("`to." + n + "` field. Alternatively you may provide the full path as ") +
    'a string in <Link to="..."> and the router will parse it for you.'
  );
}
function bc(e) {
  return e.filter(
    (t, n) => n === 0 || (t.route.path && t.route.path.length > 0)
  );
}
function e2(e, t) {
  let n = bc(e);
  return t
    ? n.map((r, l) => (l === e.length - 1 ? r.pathname : r.pathnameBase))
    : n.map((r) => r.pathnameBase);
}
function t2(e, t, n, r) {
  r === void 0 && (r = !1);
  let l;
  typeof e == "string"
    ? (l = mn(e))
    : ((l = rr({}, e)),
      X(
        !l.pathname || !l.pathname.includes("?"),
        oi("?", "pathname", "search", l)
      ),
      X(
        !l.pathname || !l.pathname.includes("#"),
        oi("#", "pathname", "hash", l)
      ),
      X(!l.search || !l.search.includes("#"), oi("#", "search", "hash", l)));
  let i = e === "" || l.pathname === "",
    o = i ? "/" : l.pathname,
    a;
  if (o == null) a = n;
  else {
    let h = t.length - 1;
    if (!r && o.startsWith("..")) {
      let v = o.split("/");
      for (; v[0] === ".."; ) v.shift(), (h -= 1);
      l.pathname = v.join("/");
    }
    a = h >= 0 ? t[h] : "/";
  }
  let u = Jc(l, a),
    f = o && o !== "/" && o.endsWith("/"),
    c = (i || o === ".") && n.endsWith("/");
  return !u.pathname.endsWith("/") && (f || c) && (u.pathname += "/"), u;
}
const Pt = (e) => e.join("/").replace(/\/\/+/g, "/"),
  n2 = (e) => e.replace(/\/+$/, "").replace(/^\/*/, "/"),
  r2 = (e) => (!e || e === "?" ? "" : e.startsWith("?") ? e : "?" + e),
  l2 = (e) => (!e || e === "#" ? "" : e.startsWith("#") ? e : "#" + e);
function i2(e) {
  return (
    e != null &&
    typeof e.status == "number" &&
    typeof e.statusText == "string" &&
    typeof e.internal == "boolean" &&
    "data" in e
  );
}
const W1 = ["post", "put", "patch", "delete"];
new Set(W1);
const o2 = ["get", ...W1];
new Set(o2);
/**
 * React Router v6.23.0
 *
 * Copyright (c) Remix Software Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.md file in the root directory of this source tree.
 *
 * @license MIT
 */ function lr() {
  return (
    (lr = Object.assign
      ? Object.assign.bind()
      : function (e) {
          for (var t = 1; t < arguments.length; t++) {
            var n = arguments[t];
            for (var r in n)
              Object.prototype.hasOwnProperty.call(n, r) && (e[r] = n[r]);
          }
          return e;
        }),
    lr.apply(this, arguments)
  );
}
const es = S.createContext(null),
  s2 = S.createContext(null),
  _l = S.createContext(null),
  Nl = S.createContext(null),
  hn = S.createContext({ outlet: null, matches: [], isDataRoute: !1 }),
  Q1 = S.createContext(null);
function Pl() {
  return S.useContext(Nl) != null;
}
function ts() {
  return Pl() || X(!1), S.useContext(Nl).location;
}
function G1(e) {
  S.useContext(_l).static || S.useLayoutEffect(e);
}
function ns() {
  let { isDataRoute: e } = S.useContext(hn);
  return e ? C2() : a2();
}
function a2() {
  Pl() || X(!1);
  let e = S.useContext(es),
    { basename: t, future: n, navigator: r } = S.useContext(_l),
    { matches: l } = S.useContext(hn),
    { pathname: i } = ts(),
    o = JSON.stringify(e2(l, n.v7_relativeSplatPath)),
    a = S.useRef(!1);
  return (
    G1(() => {
      a.current = !0;
    }),
    S.useCallback(
      function (f, c) {
        if ((c === void 0 && (c = {}), !a.current)) return;
        if (typeof f == "number") {
          r.go(f);
          return;
        }
        let h = t2(f, JSON.parse(o), i, c.relative === "path");
        e == null &&
          t !== "/" &&
          (h.pathname = h.pathname === "/" ? t : Pt([t, h.pathname])),
          (c.replace ? r.replace : r.push)(h, c.state, c);
      },
      [t, r, o, i, e]
    )
  );
}
function u2(e, t) {
  return c2(e, t);
}
function c2(e, t, n, r) {
  Pl() || X(!1);
  let { navigator: l } = S.useContext(_l),
    { matches: i } = S.useContext(hn),
    o = i[i.length - 1],
    a = o ? o.params : {};
  o && o.pathname;
  let u = o ? o.pathnameBase : "/";
  o && o.route;
  let f = ts(),
    c;
  if (t) {
    var h;
    let j = typeof t == "string" ? mn(t) : t;
    u === "/" || ((h = j.pathname) != null && h.startsWith(u)) || X(!1),
      (c = j);
  } else c = f;
  let v = c.pathname || "/",
    g = v;
  if (u !== "/") {
    let j = u.replace(/^\//, "").split("/");
    g = "/" + v.replace(/^\//, "").split("/").slice(j.length).join("/");
  }
  let x = Fc(e, { pathname: g }),
    C = h2(
      x &&
        x.map((j) =>
          Object.assign({}, j, {
            params: Object.assign({}, a, j.params),
            pathname: Pt([
              u,
              l.encodeLocation
                ? l.encodeLocation(j.pathname).pathname
                : j.pathname,
            ]),
            pathnameBase:
              j.pathnameBase === "/"
                ? u
                : Pt([
                    u,
                    l.encodeLocation
                      ? l.encodeLocation(j.pathnameBase).pathname
                      : j.pathnameBase,
                  ]),
          })
        ),
      i,
      n,
      r
    );
  return t && C
    ? S.createElement(
        Nl.Provider,
        {
          value: {
            location: lr(
              {
                pathname: "/",
                search: "",
                hash: "",
                state: null,
                key: "default",
              },
              c
            ),
            navigationType: it.Pop,
          },
        },
        C
      )
    : C;
}
function f2() {
  let e = y2(),
    t = i2(e)
      ? e.status + " " + e.statusText
      : e instanceof Error
      ? e.message
      : JSON.stringify(e),
    n = e instanceof Error ? e.stack : null,
    l = { padding: "0.5rem", backgroundColor: "rgba(200,200,200, 0.5)" };
  return S.createElement(
    S.Fragment,
    null,
    S.createElement("h2", null, "Unexpected Application Error!"),
    S.createElement("h3", { style: { fontStyle: "italic" } }, t),
    n ? S.createElement("pre", { style: l }, n) : null,
    null
  );
}
const d2 = S.createElement(f2, null);
class p2 extends S.Component {
  constructor(t) {
    super(t),
      (this.state = {
        location: t.location,
        revalidation: t.revalidation,
        error: t.error,
      });
  }
  static getDerivedStateFromError(t) {
    return { error: t };
  }
  static getDerivedStateFromProps(t, n) {
    return n.location !== t.location ||
      (n.revalidation !== "idle" && t.revalidation === "idle")
      ? { error: t.error, location: t.location, revalidation: t.revalidation }
      : {
          error: t.error !== void 0 ? t.error : n.error,
          location: n.location,
          revalidation: t.revalidation || n.revalidation,
        };
  }
  componentDidCatch(t, n) {
    console.error(
      "React Router caught the following error during render",
      t,
      n
    );
  }
  render() {
    return this.state.error !== void 0
      ? S.createElement(
          hn.Provider,
          { value: this.props.routeContext },
          S.createElement(Q1.Provider, {
            value: this.state.error,
            children: this.props.component,
          })
        )
      : this.props.children;
  }
}
function m2(e) {
  let { routeContext: t, match: n, children: r } = e,
    l = S.useContext(es);
  return (
    l &&
      l.static &&
      l.staticContext &&
      (n.route.errorElement || n.route.ErrorBoundary) &&
      (l.staticContext._deepestRenderedBoundaryId = n.route.id),
    S.createElement(hn.Provider, { value: t }, r)
  );
}
function h2(e, t, n, r) {
  var l;
  if (
    (t === void 0 && (t = []),
    n === void 0 && (n = null),
    r === void 0 && (r = null),
    e == null)
  ) {
    var i;
    if ((i = n) != null && i.errors) e = n.matches;
    else return null;
  }
  let o = e,
    a = (l = n) == null ? void 0 : l.errors;
  if (a != null) {
    let c = o.findIndex(
      (h) => h.route.id && (a == null ? void 0 : a[h.route.id]) !== void 0
    );
    c >= 0 || X(!1), (o = o.slice(0, Math.min(o.length, c + 1)));
  }
  let u = !1,
    f = -1;
  if (n && r && r.v7_partialHydration)
    for (let c = 0; c < o.length; c++) {
      let h = o[c];
      if (
        ((h.route.HydrateFallback || h.route.hydrateFallbackElement) && (f = c),
        h.route.id)
      ) {
        let { loaderData: v, errors: g } = n,
          x =
            h.route.loader &&
            v[h.route.id] === void 0 &&
            (!g || g[h.route.id] === void 0);
        if (h.route.lazy || x) {
          (u = !0), f >= 0 ? (o = o.slice(0, f + 1)) : (o = [o[0]]);
          break;
        }
      }
    }
  return o.reduceRight((c, h, v) => {
    let g,
      x = !1,
      C = null,
      j = null;
    n &&
      ((g = a && h.route.id ? a[h.route.id] : void 0),
      (C = h.route.errorElement || d2),
      u &&
        (f < 0 && v === 0
          ? (w2("route-fallback"), (x = !0), (j = null))
          : f === v &&
            ((x = !0), (j = h.route.hydrateFallbackElement || null))));
    let p = t.concat(o.slice(0, v + 1)),
      d = () => {
        let m;
        return (
          g
            ? (m = C)
            : x
            ? (m = j)
            : h.route.Component
            ? (m = S.createElement(h.route.Component, null))
            : h.route.element
            ? (m = h.route.element)
            : (m = c),
          S.createElement(m2, {
            match: h,
            routeContext: { outlet: c, matches: p, isDataRoute: n != null },
            children: m,
          })
        );
      };
    return n && (h.route.ErrorBoundary || h.route.errorElement || v === 0)
      ? S.createElement(p2, {
          location: n.location,
          revalidation: n.revalidation,
          component: C,
          error: g,
          children: d(),
          routeContext: { outlet: null, matches: p, isDataRoute: !0 },
        })
      : d();
  }, null);
}
var K1 = (function (e) {
    return (
      (e.UseBlocker = "useBlocker"),
      (e.UseRevalidator = "useRevalidator"),
      (e.UseNavigateStable = "useNavigate"),
      e
    );
  })(K1 || {}),
  Y1 = (function (e) {
    return (
      (e.UseBlocker = "useBlocker"),
      (e.UseLoaderData = "useLoaderData"),
      (e.UseActionData = "useActionData"),
      (e.UseRouteError = "useRouteError"),
      (e.UseNavigation = "useNavigation"),
      (e.UseRouteLoaderData = "useRouteLoaderData"),
      (e.UseMatches = "useMatches"),
      (e.UseRevalidator = "useRevalidator"),
      (e.UseNavigateStable = "useNavigate"),
      (e.UseRouteId = "useRouteId"),
      e
    );
  })(Y1 || {});
function v2(e) {
  let t = S.useContext(es);
  return t || X(!1), t;
}
function g2(e) {
  let t = S.useContext(s2);
  return t || X(!1), t;
}
function x2(e) {
  let t = S.useContext(hn);
  return t || X(!1), t;
}
function X1(e) {
  let t = x2(),
    n = t.matches[t.matches.length - 1];
  return n.route.id || X(!1), n.route.id;
}
function y2() {
  var e;
  let t = S.useContext(Q1),
    n = g2(),
    r = X1();
  return t !== void 0 ? t : (e = n.errors) == null ? void 0 : e[r];
}
function C2() {
  let { router: e } = v2(K1.UseNavigateStable),
    t = X1(Y1.UseNavigateStable),
    n = S.useRef(!1);
  return (
    G1(() => {
      n.current = !0;
    }),
    S.useCallback(
      function (l, i) {
        i === void 0 && (i = {}),
          n.current &&
            (typeof l == "number"
              ? e.navigate(l)
              : e.navigate(l, lr({ fromRouteId: t }, i)));
      },
      [e, t]
    )
  );
}
const xa = {};
function w2(e, t, n) {
  xa[e] || (xa[e] = !0);
}
function Pn(e) {
  X(!1);
}
function S2(e) {
  let {
    basename: t = "/",
    children: n = null,
    location: r,
    navigationType: l = it.Pop,
    navigator: i,
    static: o = !1,
    future: a,
  } = e;
  Pl() && X(!1);
  let u = t.replace(/^\/*/, "/"),
    f = S.useMemo(
      () => ({
        basename: u,
        navigator: i,
        static: o,
        future: lr({ v7_relativeSplatPath: !1 }, a),
      }),
      [u, a, i, o]
    );
  typeof r == "string" && (r = mn(r));
  let {
      pathname: c = "/",
      search: h = "",
      hash: v = "",
      state: g = null,
      key: x = "default",
    } = r,
    C = S.useMemo(() => {
      let j = Z1(c, u);
      return j == null
        ? null
        : {
            location: { pathname: j, search: h, hash: v, state: g, key: x },
            navigationType: l,
          };
    }, [u, c, h, v, g, x, l]);
  return C == null
    ? null
    : S.createElement(
        _l.Provider,
        { value: f },
        S.createElement(Nl.Provider, { children: n, value: C })
      );
}
function E2(e) {
  let { children: t, location: n } = e;
  return u2(no(t), n);
}
new Promise(() => {});
function no(e, t) {
  t === void 0 && (t = []);
  let n = [];
  return (
    S.Children.forEach(e, (r, l) => {
      if (!S.isValidElement(r)) return;
      let i = [...t, l];
      if (r.type === S.Fragment) {
        n.push.apply(n, no(r.props.children, i));
        return;
      }
      r.type !== Pn && X(!1), !r.props.index || !r.props.children || X(!1);
      let o = {
        id: r.props.id || i.join("-"),
        caseSensitive: r.props.caseSensitive,
        element: r.props.element,
        Component: r.props.Component,
        index: r.props.index,
        path: r.props.path,
        loader: r.props.loader,
        action: r.props.action,
        errorElement: r.props.errorElement,
        ErrorBoundary: r.props.ErrorBoundary,
        hasErrorBoundary:
          r.props.ErrorBoundary != null || r.props.errorElement != null,
        shouldRevalidate: r.props.shouldRevalidate,
        handle: r.props.handle,
        lazy: r.props.lazy,
      };
      r.props.children && (o.children = no(r.props.children, i)), n.push(o);
    }),
    n
  );
}
/**
 * React Router DOM v6.23.0
 *
 * Copyright (c) Remix Software Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.md file in the root directory of this source tree.
 *
 * @license MIT
 */ const j2 = "6";
try {
  window.__reactRouterVersion = j2;
} catch {}
const k2 = "startTransition",
  ya = S3[k2];
function L2(e) {
  let { basename: t, children: n, future: r, window: l } = e,
    i = S.useRef();
  i.current == null && (i.current = Dc({ window: l, v5Compat: !0 }));
  let o = i.current,
    [a, u] = S.useState({ action: o.action, location: o.location }),
    { v7_startTransition: f } = r || {},
    c = S.useCallback(
      (h) => {
        f && ya ? ya(() => u(h)) : u(h);
      },
      [u, f]
    );
  return (
    S.useLayoutEffect(() => o.listen(c), [o, c]),
    S.createElement(S2, {
      basename: t,
      children: n,
      location: a.location,
      navigationType: a.action,
      navigator: o,
      future: r,
    })
  );
}
var Ca;
(function (e) {
  (e.UseScrollRestoration = "useScrollRestoration"),
    (e.UseSubmit = "useSubmit"),
    (e.UseSubmitFetcher = "useSubmitFetcher"),
    (e.UseFetcher = "useFetcher"),
    (e.useViewTransitionState = "useViewTransitionState");
})(Ca || (Ca = {}));
var wa;
(function (e) {
  (e.UseFetcher = "useFetcher"),
    (e.UseFetchers = "useFetchers"),
    (e.UseScrollRestoration = "useScrollRestoration");
})(wa || (wa = {}));
const J1 = S.createContext(null),
  _2 = ({ children: e }) => {
    const t = ns(),
      [n, r] = S.useState(!1);
    return (
      bo("opened", (l) => {
        r(l), l && t("/");
      }),
      S.useEffect(() => {
        if (!n) return;
        const l = (i) => {
          i.key === "Escape" && (I1() ? r(!n) : Oe("Close"));
        };
        return (
          window.addEventListener("keydown", l),
          () => window.removeEventListener("keydown", l)
        );
      }, [n]),
      s.jsx(J1.Provider, {
        value: { opened: n, setOpened: r },
        children: n && e,
      })
    );
  },
  N2 = () => S.useContext(J1),
  P2 = "" + new URL("logo-2KEw83bQ.png", import.meta.url).href;
function q1(e) {
  var t,
    n,
    r = "";
  if (typeof e == "string" || typeof e == "number") r += e;
  else if (typeof e == "object")
    if (Array.isArray(e)) {
      var l = e.length;
      for (t = 0; t < l; t++)
        e[t] && (n = q1(e[t])) && (r && (r += " "), (r += n));
    } else for (n in e) e[n] && (r && (r += " "), (r += n));
  return r;
}
function zn() {
  for (var e, t, n = 0, r = "", l = arguments.length; n < l; n++)
    (e = arguments[n]) && (t = q1(e)) && (r && (r += " "), (r += t));
  return r;
}
function rs() {
  const e = ns(),
    { pathname: t } = ts();
  return s.jsxs("div", {
    className:
      "w-full flex flex-col items-center gap-5 border-b-[.0625rem] border-white/20 pb-5",
    children: [
      s.jsx("img", { src: P2, alt: "logo", className: "size-[4.375rem]" }),
      s.jsxs("div", {
        className: "flex items-center gap-2",
        children: [
          s.jsx("button", {
            onClick: () => e("/"),
            className: zn(
              "text-xs text-[#D9D9D9] font-extrabold w-[11.54rem] h-8 rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/15",
              t === "/" && "!bg-primary !text-[#1E1E1E]"
            ),
            children: "INICIO",
          }),
          s.jsx("button", {
            onClick: () => e("/craft"),
            className: zn(
              "text-xs text-[#D9D9D9] font-extrabold w-[11.54rem] h-8 rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/15",
              t === "/craft" && "!bg-primary !text-[#1E1E1E]"
            ),
            children: "CRAFT",
          }),
          s.jsx("button", {
            onClick: () => e("/storage"),
            className: zn(
              "text-xs text-[#D9D9D9] font-extrabold w-[11.54rem] h-8 rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/15",
              t === "/storage" && "!bg-primary !text-[#1E1E1E]"
            ),
            children: "ARMAZEM",
          }),
          s.jsx("button", {
            onClick: () => e("/ranking"),
            className: zn(
              "text-xs text-[#D9D9D9] font-extrabold w-[11.54rem] h-8 rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/15",
              t === "/ranking" && "!bg-primary !text-[#1E1E1E]"
            ),
            children: "RANKING",
          }),
        ],
      }),
    ],
  });
}
function z2() {
  var a, u, f, c, h, v;
  const [e, t] = S.useState([]),
    [n, r] = S.useState(null);
  function l(g) {
    g && r(g);
  }
  function i() {
    Oe("SaveAll", null, !0);
  }
  function o() {
    Oe("SaveItem", { item: n }, !0);
  }
  return (
    bo("updateStorage", t),
    S.useEffect(() => {
      Oe("GetStorage", {}, [
        { name: "Gatilhos", image: "AMMO_PISTOL_MK2", amount: 33223 },
        { name: "Aluminio", image: "aluminio", amount: 33223 },
        { name: "Maconha", image: "maconha", amount: 33223 },
      ]).then((g) => {
        t(g), r(g[0]);
      });
    }, []),
    s.jsxs("div", {
      className:
        "w-screen h-screen bg-background bg-cover bg-no-repeat bg-center flex items-center justify-center",
      children: [
        s.jsx("div", {
          className:
            "h-full flex items-center justify-center border-r-[.0625rem] border-white/20 pr-12",
          children: s.jsxs("div", {
            className: "w-[10.6875rem] h-[26.75rem] relative",
            children: [
              s.jsxs("div", {
                onClick: () => l(e[0]),
                className:
                  "size-[8.5rem] absolute top-0 right-0 cursor-pointer",
                children: [
                  e[0] &&
                    s.jsxs("div", {
                      className:
                        "size-full flex flex-col items-center justify-center z-20 relative",
                      children: [
                        s.jsx("p", {
                          className: "text-white text-[0.8125rem] font-bold",
                          children: e[0].name,
                        }),
                        s.jsx("img", {
                          src: `http://127.0.0.1/images/${e[0].image}.PNG`,
                          alt: "",
                          className: "size-[3.125rem] object-contain",
                        }),
                        s.jsxs("p", {
                          className:
                            "absolute left-1/2 -translate-x-1/2 bottom-2.5 h-[1.1875rem] w-[3.3125rem] bg-primary flex items-center justify-center text-[#0A0A0A] text-xs font-semibold",
                          style: {
                            borderRadius: "0.6875rem 0.6875rem 0rem 0rem",
                          },
                          children: [e[0].amount, "x"],
                        }),
                      ],
                    }),
                  (n == null ? void 0 : n.name) ===
                  ((a = e[0]) == null ? void 0 : a.name)
                    ? s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 134 118",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint0_radial_328_2435)",
                            "fill-opacity": "0.45",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint1_linear_328_2435)",
                            "fill-opacity": "0.5",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsxs("defs", {
                            children: [
                              s.jsxs("radialGradient", {
                                id: "paint0_radial_328_2435",
                                cx: "0",
                                cy: "0",
                                r: "1",
                                gradientUnits: "userSpaceOnUse",
                                gradientTransform:
                                  "translate(66.9999 -9.19428) rotate(90) scale(151.009 1540.96)",
                                children: [
                                  s.jsx("stop", {}),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-opacity": "0",
                                  }),
                                ],
                              }),
                              s.jsxs("linearGradient", {
                                id: "paint1_linear_328_2435",
                                x1: "86.2667",
                                y1: "5.05333",
                                x2: "61.4634",
                                y2: "152.42",
                                gradientUnits: "userSpaceOnUse",
                                children: [
                                  s.jsx("stop", {
                                    "stop-color": "#12B6FF",
                                    "stop-opacity": "0",
                                  }),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-color": "#12B6FF",
                                  }),
                                ],
                              }),
                            ],
                          }),
                        ],
                      })
                    : s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 136 136",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M4.33012 73.5C2.36516 70.0966 2.36516 65.9034 4.33012 62.5L31.4019 15.6103C33.3669 12.2069 36.9983 10.1103 40.9282 10.1103L95.0718 10.1103C99.0017 10.1103 102.633 12.2069 104.598 15.6103L131.67 62.5C133.635 65.9034 133.635 70.0966 131.67 73.5L104.598 120.39C102.633 123.793 99.0017 125.89 95.0718 125.89L40.9282 125.89C36.9983 125.89 33.3669 123.793 31.4019 120.39L4.33012 73.5Z",
                            fill: "url(#paint0_radial_328_2446)",
                            "fill-opacity": "0.45",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsx("defs", {
                            children: s.jsxs("radialGradient", {
                              id: "paint0_radial_328_2446",
                              cx: "0",
                              cy: "0",
                              r: "1",
                              gradientUnits: "userSpaceOnUse",
                              gradientTransform:
                                "translate(67.9999 -0.194276) rotate(90) scale(151.009 1540.96)",
                              children: [
                                s.jsx("stop", {}),
                                s.jsx("stop", {
                                  offset: "1",
                                  "stop-opacity": "0",
                                }),
                              ],
                            }),
                          }),
                        ],
                      }),
                ],
              }),
              s.jsxs("div", {
                onClick: () => l(e[1]),
                className:
                  "size-[8.5rem] absolute top-1/2 left-0 -translate-y-1/2 cursor-pointer",
                children: [
                  e[1] &&
                    s.jsxs("div", {
                      className:
                        "size-full flex flex-col items-center justify-center z-20 relative",
                      children: [
                        s.jsx("p", {
                          className: "text-white text-[0.8125rem] font-bold",
                          children: e[1].name,
                        }),
                        s.jsx("img", {
                          src: `http://127.0.0.1/images/${e[1].image}.PNG`,
                          alt: "",
                          className: "size-[3.125rem] object-contain",
                        }),
                        s.jsxs("p", {
                          className:
                            "absolute left-1/2 -translate-x-1/2 bottom-2.5 h-[1.1875rem] w-[3.3125rem] bg-primary flex items-center justify-center text-[#0A0A0A] text-xs font-semibold",
                          style: {
                            borderRadius: "0.6875rem 0.6875rem 0rem 0rem",
                          },
                          children: [e[1].amount, "x"],
                        }),
                      ],
                    }),
                  (n == null ? void 0 : n.name) ===
                  ((u = e[1]) == null ? void 0 : u.name)
                    ? s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 134 118",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint0_radial_328_2435)",
                            "fill-opacity": "0.45",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint1_linear_328_2435)",
                            "fill-opacity": "0.5",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsxs("defs", {
                            children: [
                              s.jsxs("radialGradient", {
                                id: "paint0_radial_328_2435",
                                cx: "0",
                                cy: "0",
                                r: "1",
                                gradientUnits: "userSpaceOnUse",
                                gradientTransform:
                                  "translate(66.9999 -9.19428) rotate(90) scale(151.009 1540.96)",
                                children: [
                                  s.jsx("stop", {}),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-opacity": "0",
                                  }),
                                ],
                              }),
                              s.jsxs("linearGradient", {
                                id: "paint1_linear_328_2435",
                                x1: "86.2667",
                                y1: "5.05333",
                                x2: "61.4634",
                                y2: "152.42",
                                gradientUnits: "userSpaceOnUse",
                                children: [
                                  s.jsx("stop", {
                                    "stop-color": "#12B6FF",
                                    "stop-opacity": "0",
                                  }),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-color": "#12B6FF",
                                  }),
                                ],
                              }),
                            ],
                          }),
                        ],
                      })
                    : s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 136 136",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M4.33012 73.5C2.36516 70.0966 2.36516 65.9034 4.33012 62.5L31.4019 15.6103C33.3669 12.2069 36.9983 10.1103 40.9282 10.1103L95.0718 10.1103C99.0017 10.1103 102.633 12.2069 104.598 15.6103L131.67 62.5C133.635 65.9034 133.635 70.0966 131.67 73.5L104.598 120.39C102.633 123.793 99.0017 125.89 95.0718 125.89L40.9282 125.89C36.9983 125.89 33.3669 123.793 31.4019 120.39L4.33012 73.5Z",
                            fill: "url(#paint0_radial_328_2446)",
                            "fill-opacity": "0.45",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsx("defs", {
                            children: s.jsxs("radialGradient", {
                              id: "paint0_radial_328_2446",
                              cx: "0",
                              cy: "0",
                              r: "1",
                              gradientUnits: "userSpaceOnUse",
                              gradientTransform:
                                "translate(67.9999 -0.194276) rotate(90) scale(151.009 1540.96)",
                              children: [
                                s.jsx("stop", {}),
                                s.jsx("stop", {
                                  offset: "1",
                                  "stop-opacity": "0",
                                }),
                              ],
                            }),
                          }),
                        ],
                      }),
                ],
              }),
              s.jsxs("div", {
                onClick: () => l(e[2]),
                className:
                  "size-[8.5rem] absolute bottom-0 right-0 cursor-pointer",
                children: [
                  e[2] &&
                    s.jsxs("div", {
                      className:
                        "size-full flex flex-col items-center justify-center z-20 relative",
                      children: [
                        s.jsx("p", {
                          className: "text-white text-[0.8125rem] font-bold",
                          children: e[2].name,
                        }),
                        s.jsx("img", {
                          src: `http://127.0.0.1/images/${e[2].image}.PNG`,
                          alt: "",
                          className: "size-[3.125rem] object-contain",
                        }),
                        s.jsxs("p", {
                          className:
                            "absolute left-1/2 -translate-x-1/2 bottom-2.5 h-[1.1875rem] w-[3.3125rem] bg-primary flex items-center justify-center text-[#0A0A0A] text-xs font-semibold",
                          style: {
                            borderRadius: "0.6875rem 0.6875rem 0rem 0rem",
                          },
                          children: [e[2].amount, "x"],
                        }),
                      ],
                    }),
                  (n == null ? void 0 : n.name) ===
                  ((f = e[2]) == null ? void 0 : f.name)
                    ? s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 134 118",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint0_radial_328_2435)",
                            "fill-opacity": "0.45",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint1_linear_328_2435)",
                            "fill-opacity": "0.5",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsxs("defs", {
                            children: [
                              s.jsxs("radialGradient", {
                                id: "paint0_radial_328_2435",
                                cx: "0",
                                cy: "0",
                                r: "1",
                                gradientUnits: "userSpaceOnUse",
                                gradientTransform:
                                  "translate(66.9999 -9.19428) rotate(90) scale(151.009 1540.96)",
                                children: [
                                  s.jsx("stop", {}),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-opacity": "0",
                                  }),
                                ],
                              }),
                              s.jsxs("linearGradient", {
                                id: "paint1_linear_328_2435",
                                x1: "86.2667",
                                y1: "5.05333",
                                x2: "61.4634",
                                y2: "152.42",
                                gradientUnits: "userSpaceOnUse",
                                children: [
                                  s.jsx("stop", {
                                    "stop-color": "#12B6FF",
                                    "stop-opacity": "0",
                                  }),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-color": "#12B6FF",
                                  }),
                                ],
                              }),
                            ],
                          }),
                        ],
                      })
                    : s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 136 136",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M4.33012 73.5C2.36516 70.0966 2.36516 65.9034 4.33012 62.5L31.4019 15.6103C33.3669 12.2069 36.9983 10.1103 40.9282 10.1103L95.0718 10.1103C99.0017 10.1103 102.633 12.2069 104.598 15.6103L131.67 62.5C133.635 65.9034 133.635 70.0966 131.67 73.5L104.598 120.39C102.633 123.793 99.0017 125.89 95.0718 125.89L40.9282 125.89C36.9983 125.89 33.3669 123.793 31.4019 120.39L4.33012 73.5Z",
                            fill: "url(#paint0_radial_328_2446)",
                            "fill-opacity": "0.45",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsx("defs", {
                            children: s.jsxs("radialGradient", {
                              id: "paint0_radial_328_2446",
                              cx: "0",
                              cy: "0",
                              r: "1",
                              gradientUnits: "userSpaceOnUse",
                              gradientTransform:
                                "translate(67.9999 -0.194276) rotate(90) scale(151.009 1540.96)",
                              children: [
                                s.jsx("stop", {}),
                                s.jsx("stop", {
                                  offset: "1",
                                  "stop-opacity": "0",
                                }),
                              ],
                            }),
                          }),
                        ],
                      }),
                ],
              }),
            ],
          }),
        }),
        s.jsxs("div", {
          className:
            "w-[60rem] h-full flex flex-col items-center pt-5 gap-5 relative",
          children: [
            s.jsx(rs, {}),
            s.jsxs("div", {
              className:
                "flex flex-col items-center absolute left-1/2 -translate-x-1/2 top-1/2 -translate-y-1/2",
              children: [
                s.jsxs("div", {
                  className: "flex flex-col items-center",
                  children: [
                    s.jsxs("p", {
                      className:
                        "text-white text-[1.1875rem] font-bold leading-none",
                      children: [n == null ? void 0 : n.amount, "x"],
                    }),
                    s.jsx("h2", {
                      className:
                        "text-primary text-[3.125rem] font-black leading-none uppercase",
                      style: {
                        textShadow: "0 0 .875rem rgba(18, 182, 255, 0.45)",
                      },
                      children: n == null ? void 0 : n.name,
                    }),
                  ],
                }),
                s.jsx("div", {
                  className:
                    "size-[32rem] bg-center-details bg-cover bg-no-repeat bg-center flex items-center justify-center relative",
                  children: s.jsx("img", {
                    src: `http://127.0.0.1/images/${
                      n == null ? void 0 : n.image
                    }.png`,
                    className:
                      "size-full object-contain absolute top-1/2 -translate-y-1/2 left-1/2 -translate-x-1/2",
                  }),
                }),
                s.jsxs("div", {
                  className: "flex items-center gap-2.5 mt-12",
                  children: [
                    s.jsx("button", {
                      onClick: i,
                      className:
                        "w-[11.875rem] h-8 rounded-[0.5625rem] text-[#1E1E1E] text-xs font-extrabold bg-[#D9D9D9]",
                      children: "GUARDAR TODOS",
                    }),
                    s.jsx("button", {
                      onClick: o,
                      className:
                        "w-[11.875rem] h-8 rounded-[0.5625rem] text-[#1E1E1E] text-xs font-extrabold bg-primary",
                      children: "GUARDAR FARM",
                    }),
                  ],
                }),
              ],
            }),
          ],
        }),
        s.jsx("div", {
          className:
            "h-full flex items-center justify-center border-l-[.0625rem] border-white/20 pl-12",
          children: s.jsxs("div", {
            className: "w-[10.6875rem] h-[26.75rem] relative ",
            children: [
              s.jsxs("div", {
                onClick: () => l(e[3]),
                className: "size-[8.5rem] absolute top-0 left-0 cursor-pointer",
                children: [
                  e[3] &&
                    s.jsxs("div", {
                      className:
                        "size-full flex flex-col items-center justify-center z-20 relative",
                      children: [
                        s.jsx("p", {
                          className: "text-white text-[0.8125rem] font-bold",
                          children: e[3].name,
                        }),
                        s.jsx("img", {
                          src: `http://127.0.0.1/images/${e[3].image}.PNG`,
                          alt: "",
                          className: "size-[3.125rem] object-contain",
                        }),
                        s.jsxs("p", {
                          className:
                            "absolute left-1/2 -translate-x-1/2 bottom-2.5 h-[1.1875rem] w-[3.3125rem] bg-primary flex items-center justify-center text-[#0A0A0A] text-xs font-semibold",
                          style: {
                            borderRadius: "0.6875rem 0.6875rem 0rem 0rem",
                          },
                          children: [e[3].amount, "x"],
                        }),
                      ],
                    }),
                  (n == null ? void 0 : n.name) ===
                  ((c = e[3]) == null ? void 0 : c.name)
                    ? s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 134 118",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint0_radial_328_2435)",
                            "fill-opacity": "0.45",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint1_linear_328_2435)",
                            "fill-opacity": "0.5",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsxs("defs", {
                            children: [
                              s.jsxs("radialGradient", {
                                id: "paint0_radial_328_2435",
                                cx: "0",
                                cy: "0",
                                r: "1",
                                gradientUnits: "userSpaceOnUse",
                                gradientTransform:
                                  "translate(66.9999 -9.19428) rotate(90) scale(151.009 1540.96)",
                                children: [
                                  s.jsx("stop", {}),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-opacity": "0",
                                  }),
                                ],
                              }),
                              s.jsxs("linearGradient", {
                                id: "paint1_linear_328_2435",
                                x1: "86.2667",
                                y1: "5.05333",
                                x2: "61.4634",
                                y2: "152.42",
                                gradientUnits: "userSpaceOnUse",
                                children: [
                                  s.jsx("stop", {
                                    "stop-color": "#12B6FF",
                                    "stop-opacity": "0",
                                  }),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-color": "#12B6FF",
                                  }),
                                ],
                              }),
                            ],
                          }),
                        ],
                      })
                    : s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 136 136",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M4.33012 73.5C2.36516 70.0966 2.36516 65.9034 4.33012 62.5L31.4019 15.6103C33.3669 12.2069 36.9983 10.1103 40.9282 10.1103L95.0718 10.1103C99.0017 10.1103 102.633 12.2069 104.598 15.6103L131.67 62.5C133.635 65.9034 133.635 70.0966 131.67 73.5L104.598 120.39C102.633 123.793 99.0017 125.89 95.0718 125.89L40.9282 125.89C36.9983 125.89 33.3669 123.793 31.4019 120.39L4.33012 73.5Z",
                            fill: "url(#paint0_radial_328_2446)",
                            "fill-opacity": "0.45",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsx("defs", {
                            children: s.jsxs("radialGradient", {
                              id: "paint0_radial_328_2446",
                              cx: "0",
                              cy: "0",
                              r: "1",
                              gradientUnits: "userSpaceOnUse",
                              gradientTransform:
                                "translate(67.9999 -0.194276) rotate(90) scale(151.009 1540.96)",
                              children: [
                                s.jsx("stop", {}),
                                s.jsx("stop", {
                                  offset: "1",
                                  "stop-opacity": "0",
                                }),
                              ],
                            }),
                          }),
                        ],
                      }),
                ],
              }),
              s.jsxs("div", {
                onClick: () => l(e[4]),
                className:
                  "size-[8.5rem] absolute top-1/2 right-0 -translate-y-1/2 cursor-pointer",
                children: [
                  e[4] &&
                    s.jsxs("div", {
                      className:
                        "size-full flex flex-col items-center justify-center z-20 relative",
                      children: [
                        s.jsx("p", {
                          className: "text-white text-[0.8125rem] font-bold",
                          children: e[4].name,
                        }),
                        s.jsx("img", {
                          src: `http://127.0.0.1/images/${e[4].image}.PNG`,
                          alt: "",
                          className: "size-[3.125rem] object-contain",
                        }),
                        s.jsxs("p", {
                          className:
                            "absolute left-1/2 -translate-x-1/2 bottom-2.5 h-[1.1875rem] w-[3.3125rem] bg-primary flex items-center justify-center text-[#0A0A0A] text-xs font-semibold",
                          style: {
                            borderRadius: "0.6875rem 0.6875rem 0rem 0rem",
                          },
                          children: [e[4].amount, "x"],
                        }),
                      ],
                    }),
                  (n == null ? void 0 : n.name) ===
                  ((h = e[4]) == null ? void 0 : h.name)
                    ? s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 134 118",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint0_radial_328_2435)",
                            "fill-opacity": "0.45",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint1_linear_328_2435)",
                            "fill-opacity": "0.5",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsxs("defs", {
                            children: [
                              s.jsxs("radialGradient", {
                                id: "paint0_radial_328_2435",
                                cx: "0",
                                cy: "0",
                                r: "1",
                                gradientUnits: "userSpaceOnUse",
                                gradientTransform:
                                  "translate(66.9999 -9.19428) rotate(90) scale(151.009 1540.96)",
                                children: [
                                  s.jsx("stop", {}),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-opacity": "0",
                                  }),
                                ],
                              }),
                              s.jsxs("linearGradient", {
                                id: "paint1_linear_328_2435",
                                x1: "86.2667",
                                y1: "5.05333",
                                x2: "61.4634",
                                y2: "152.42",
                                gradientUnits: "userSpaceOnUse",
                                children: [
                                  s.jsx("stop", {
                                    "stop-color": "#12B6FF",
                                    "stop-opacity": "0",
                                  }),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-color": "#12B6FF",
                                  }),
                                ],
                              }),
                            ],
                          }),
                        ],
                      })
                    : s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 136 136",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M4.33012 73.5C2.36516 70.0966 2.36516 65.9034 4.33012 62.5L31.4019 15.6103C33.3669 12.2069 36.9983 10.1103 40.9282 10.1103L95.0718 10.1103C99.0017 10.1103 102.633 12.2069 104.598 15.6103L131.67 62.5C133.635 65.9034 133.635 70.0966 131.67 73.5L104.598 120.39C102.633 123.793 99.0017 125.89 95.0718 125.89L40.9282 125.89C36.9983 125.89 33.3669 123.793 31.4019 120.39L4.33012 73.5Z",
                            fill: "url(#paint0_radial_328_2446)",
                            "fill-opacity": "0.45",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsx("defs", {
                            children: s.jsxs("radialGradient", {
                              id: "paint0_radial_328_2446",
                              cx: "0",
                              cy: "0",
                              r: "1",
                              gradientUnits: "userSpaceOnUse",
                              gradientTransform:
                                "translate(67.9999 -0.194276) rotate(90) scale(151.009 1540.96)",
                              children: [
                                s.jsx("stop", {}),
                                s.jsx("stop", {
                                  offset: "1",
                                  "stop-opacity": "0",
                                }),
                              ],
                            }),
                          }),
                        ],
                      }),
                ],
              }),
              s.jsxs("div", {
                onClick: () => l(e[5]),
                className:
                  "size-[8.5rem] absolute bottom-0 left-0 cursor-pointer",
                children: [
                  e[5] &&
                    s.jsxs("div", {
                      className:
                        "size-full flex flex-col items-center justify-center z-20 relative",
                      children: [
                        s.jsx("p", {
                          className: "text-white text-[0.8125rem] font-bold",
                          children: e[5].name,
                        }),
                        s.jsx("img", {
                          src: `http://127.0.0.1/images/${e[5].image}.PNG`,
                          alt: "",
                          className: "size-[3.125rem] object-contain",
                        }),
                        s.jsxs("p", {
                          className:
                            "absolute left-1/2 -translate-x-1/2 bottom-2.5 h-[1.1875rem] w-[3.3125rem] bg-primary flex items-center justify-center text-[#0A0A0A] text-xs font-semibold",
                          style: {
                            borderRadius: "0.6875rem 0.6875rem 0rem 0rem",
                          },
                          children: [e[5].amount, "x"],
                        }),
                      ],
                    }),
                  (n == null ? void 0 : n.name) ===
                  ((v = e[5]) == null ? void 0 : v.name)
                    ? s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 134 118",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint0_radial_328_2435)",
                            "fill-opacity": "0.45",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            fill: "url(#paint1_linear_328_2435)",
                            "fill-opacity": "0.5",
                          }),
                          s.jsx("path", {
                            d: "M3.33012 64.5C1.36516 61.0966 1.36516 56.9034 3.33012 53.5L30.4019 6.61027C32.3669 3.20686 35.9983 1.11027 39.9282 1.11027L94.0718 1.11027C98.0017 1.11027 101.633 3.20686 103.598 6.61027L130.67 53.5C132.635 56.9034 132.635 61.0966 130.67 64.5L103.598 111.39C101.633 114.793 98.0017 116.89 94.0718 116.89L39.9282 116.89C35.9983 116.89 32.3669 114.793 30.4019 111.39L3.33012 64.5Z",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsxs("defs", {
                            children: [
                              s.jsxs("radialGradient", {
                                id: "paint0_radial_328_2435",
                                cx: "0",
                                cy: "0",
                                r: "1",
                                gradientUnits: "userSpaceOnUse",
                                gradientTransform:
                                  "translate(66.9999 -9.19428) rotate(90) scale(151.009 1540.96)",
                                children: [
                                  s.jsx("stop", {}),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-opacity": "0",
                                  }),
                                ],
                              }),
                              s.jsxs("linearGradient", {
                                id: "paint1_linear_328_2435",
                                x1: "86.2667",
                                y1: "5.05333",
                                x2: "61.4634",
                                y2: "152.42",
                                gradientUnits: "userSpaceOnUse",
                                children: [
                                  s.jsx("stop", {
                                    "stop-color": "#12B6FF",
                                    "stop-opacity": "0",
                                  }),
                                  s.jsx("stop", {
                                    offset: "1",
                                    "stop-color": "#12B6FF",
                                  }),
                                ],
                              }),
                            ],
                          }),
                        ],
                      })
                    : s.jsxs("svg", {
                        className:
                          "size-full absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-10",
                        viewBox: "0 0 136 136",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          s.jsx("path", {
                            d: "M4.33012 73.5C2.36516 70.0966 2.36516 65.9034 4.33012 62.5L31.4019 15.6103C33.3669 12.2069 36.9983 10.1103 40.9282 10.1103L95.0718 10.1103C99.0017 10.1103 102.633 12.2069 104.598 15.6103L131.67 62.5C133.635 65.9034 133.635 70.0966 131.67 73.5L104.598 120.39C102.633 123.793 99.0017 125.89 95.0718 125.89L40.9282 125.89C36.9983 125.89 33.3669 123.793 31.4019 120.39L4.33012 73.5Z",
                            fill: "url(#paint0_radial_328_2446)",
                            "fill-opacity": "0.45",
                            stroke: "#12B6FF",
                            "stroke-width": "2",
                          }),
                          s.jsx("defs", {
                            children: s.jsxs("radialGradient", {
                              id: "paint0_radial_328_2446",
                              cx: "0",
                              cy: "0",
                              r: "1",
                              gradientUnits: "userSpaceOnUse",
                              gradientTransform:
                                "translate(67.9999 -0.194276) rotate(90) scale(151.009 1540.96)",
                              children: [
                                s.jsx("stop", {}),
                                s.jsx("stop", {
                                  offset: "1",
                                  "stop-opacity": "0",
                                }),
                              ],
                            }),
                          }),
                        ],
                      }),
                ],
              }),
            ],
          }),
        }),
      ],
    })
  );
}
function M2({ player: e }) {
  return s.jsxs("div", {
    className:
      "w-[38.5rem] h-[3.625rem] flex flex-none items-center gap-2.5 pl-[1.75rem]",
    children: [
      s.jsxs("div", {
        className:
          "w-[27.5rem] h-[2.0625rem] rounded-lg border-[.0625rem] border-white/15 bg-white/10 flex items-center relative pl-[3.31rem]",
        children: [
          s.jsx("div", {
            className:
              "size-[3.625rem] bg-polygon-ranking bg-contain bg-center bg-no-repeat flex items-center justify-center absolute -left-8",
            children: s.jsx("p", {
              className: "text-xl text-[#1E1E1E] font-extrabold uppercase",
              children: e.position,
            }),
          }),
          s.jsxs("p", {
            className:
              "text-white text-[0.9375rem] font-bold leading-none capitalize w-[5.8125rem] truncate",
            children: ["#", e.id],
          }),
          s.jsx("p", {
            className:
              "text-white text-[0.9375rem] font-bold leading-none capitalize flex-1 truncate",
            children: e.name,
          }),
        ],
      }),
      s.jsx("div", {
        className:
          "w-[8.625rem] h-[2.0625rem] flex items-center justify-center rounded-lg border-[.0625rem] border-white/15 bg-white/10",
        children: s.jsxs("p", {
          className:
            "text-white text-[0.9375rem] font-bold leading-none capitalize",
          children: [e.craft, "x"],
        }),
      }),
    ],
  });
}
function T2() {
  var n, r, l, i, o, a, u, f, c;
  const [e, t] = S.useState([]);
  return (
    S.useEffect(() => {
      Oe("GetRanking", {}, [
        { position: 1, id: 1, name: "test", craft: 222 },
        { position: 2, id: 432, name: "joaozinho", craft: 156 },
        { position: 3, id: 765, name: "pedrin", craft: 134 },
        { position: 4, id: 234, name: "marcos", craft: 98 },
        { position: 5, id: 876, name: "lucas", craft: 87 },
        { position: 6, id: 543, name: "matheus", craft: 76 },
        { position: 7, id: 987, name: "carlos", craft: 65 },
        { position: 8, id: 321, name: "felipe", craft: 54 },
        { position: 9, id: 654, name: "bruno", craft: 43 },
        { position: 10, id: 789, name: "rafael", craft: 32 },
      ]).then(t);
    }, []),
    s.jsxs("div", {
      className:
        "w-screen h-screen pt-5 bg-background bg-cover bg-no-repeat bg-center flex flex-col gap-9",
      children: [
        s.jsx(rs, {}),
        s.jsxs("div", {
          className: "flex flex-col items-center gap-8",
          children: [
            s.jsxs("div", {
              className: "flex flex-col items-center",
              children: [
                s.jsx("p", {
                  className:
                    "text-white text-[1.0625rem] font-extrabold leading-none",
                  children: "RANKING",
                }),
                s.jsx("h2", {
                  className:
                    "text-primary text-[2.25rem] font-black leading-none",
                  style: { textShadow: "0 0 .875rem rgba(18, 182, 255, 0.45)" },
                  children: "TOP CRAFT",
                }),
              ],
            }),
            s.jsxs("div", {
              className: "h-[9.5625rem] flex gap-16 justify-center",
              children: [
                s.jsxs("div", {
                  className: "flex flex-col items-center gap-2 self-end",
                  children: [
                    s.jsxs("svg", {
                      className: "w-[4.4375rem] h-[4.375rem]",
                      viewBox: "0 0 71 70",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M4.83013 40.5C2.86517 37.0966 2.86516 32.9034 4.83013 29.5L15.4019 11.1891C17.3669 7.7857 20.9983 5.68911 24.9282 5.68911L46.0718 5.68911C50.0017 5.68911 53.6331 7.7857 55.5981 11.1891L66.1699 29.5C68.1348 32.9034 68.1348 37.0966 66.1699 40.5L55.5981 58.8109C53.6331 62.2143 50.0017 64.3109 46.0718 64.3109L24.9282 64.3109C20.9983 64.3109 17.3669 62.2143 15.4019 58.8109L4.83013 40.5Z",
                          fill: "url(#paint0_radial_328_2988)",
                          "fill-opacity": "0.45",
                          stroke: "#BEBEBE",
                          "stroke-width": "2",
                        }),
                        s.jsx("path", {
                          d: "M10.3868 40C8.60042 36.906 8.60042 33.094 10.3868 30L18.6132 15.7513C20.3996 12.6573 23.7008 10.7513 27.2735 10.7513L43.7265 10.7513C47.2992 10.7513 50.6004 12.6573 52.3868 15.7513L60.6132 30C62.3996 33.094 62.3996 36.906 60.6132 40L52.3868 54.2487C50.6004 57.3427 47.2992 59.2487 43.7265 59.2487L27.2735 59.2487C23.7008 59.2487 20.3996 57.3427 18.6132 54.2487L10.3868 40Z",
                          fill: "#BEBEBE",
                        }),
                        s.jsx("path", {
                          d: "M36.0084 23.0981C33.6925 23.0981 31.5967 23.2429 30.0558 23.4821C29.2854 23.6017 28.6566 23.7416 28.1833 23.9153C27.9466 24.0021 27.7482 24.0938 27.5755 24.2247C27.4111 24.3495 27.2378 24.5477 27.2216 24.8214H27.1835C27.1835 25.3333 27.2019 25.8382 27.2375 26.3354H25.9219C25.9158 25.9315 25.922 25.5268 25.941 25.123L24.5794 24.804C24.1456 30.221 26.2555 35.4933 30.1384 39.248L30.9334 37.7452C30.7218 37.5699 30.5159 37.3879 30.3161 37.1993C30.6163 36.8856 30.944 36.5993 31.2951 36.344C31.9791 37.0129 32.7263 37.5406 33.52 37.9007C34.643 38.8017 33.929 39.392 32.3267 39.7415C35.3158 40.2798 34.3045 42.9035 31.6094 44.4293C31.5007 44.443 31.3933 44.4558 31.2905 44.4705C30.6787 44.5578 30.1796 44.6589 29.7972 44.7879C29.606 44.8524 29.4439 44.9199 29.2942 45.0243C29.1444 45.1287 28.9577 45.314 28.9577 45.6035C28.9577 45.893 29.1444 46.0768 29.2942 46.1812C29.4439 46.2855 29.606 46.3532 29.7972 46.4177C30.1796 46.5466 30.6788 46.6478 31.2905 46.735C32.514 46.9095 34.174 47.0159 36.0084 47.0159C37.8427 47.0159 39.5027 46.9095 40.7262 46.735C41.3381 46.6478 41.8372 46.5466 42.2196 46.4177C42.4107 46.3532 42.5728 46.2855 42.7225 46.1812C42.8723 46.0769 43.059 45.8931 43.059 45.6036C43.059 45.314 42.8723 45.1287 42.7225 45.0243C42.5728 44.92 42.4108 44.8523 42.2195 44.7879C41.8371 44.6589 41.3379 44.5578 40.7261 44.4705C40.6239 44.4559 40.5169 44.4429 40.4088 44.4292C37.7135 42.9035 36.7022 40.2799 39.6915 39.7415C38.0884 39.3918 37.3743 38.8009 38.4997 37.8992C39.299 37.5361 40.0509 37.0026 40.7388 36.3265C41.0764 36.5688 41.3908 36.8362 41.6767 37.1247C41.4675 37.3378 41.2521 37.5447 41.0308 37.7451L41.8528 39.248C45.8705 35.594 47.7533 30.1312 47.4403 24.7753L46.0518 25.18C46.0747 25.5665 46.0843 25.9514 46.0804 26.3353H44.7807C44.8167 25.8314 44.8347 25.3265 44.8346 24.8213H44.7966C44.7802 24.5476 44.6055 24.3494 44.4411 24.2246C44.2683 24.0936 44.0699 24.0021 43.8332 23.9152C43.36 23.7415 42.7311 23.6015 41.9607 23.482C40.4199 23.2428 38.3241 23.0979 36.0081 23.0979L36.0084 23.0981ZM36.0084 24.0471C38.2845 24.0471 40.3464 24.192 41.8149 24.4199C42.5492 24.5339 43.1382 24.6704 43.5066 24.8056C43.5594 24.825 43.5967 24.8437 43.6399 24.8627C43.5967 24.8817 43.5596 24.9004 43.5066 24.9198C43.1383 25.055 42.5491 25.193 41.8149 25.307C40.3464 25.535 38.2845 25.68 36.0084 25.68C33.7323 25.68 31.6704 25.535 30.2018 25.307C29.4675 25.193 28.8785 25.055 28.5102 24.9198C28.4569 24.9002 28.4203 24.8818 28.3769 24.8627C28.4202 24.8436 28.457 24.8251 28.5102 24.8055C28.8785 24.6703 29.4676 24.5338 30.2019 24.4199C31.6704 24.1919 33.7323 24.0471 36.0084 24.0471ZM25.9918 27.6969H27.3803C27.7895 30.636 28.8139 33.2234 30.2336 35.1237C29.8795 35.4151 29.5528 35.7314 29.2592 36.0727C27.2966 33.7136 26.261 30.7586 25.9918 27.6969ZM44.638 27.6969H46.0091C45.7255 30.7251 44.5995 33.5953 42.7051 35.9648C42.4259 35.6544 42.1229 35.3663 41.799 35.103C43.2113 33.2048 44.2301 30.6254 44.638 27.697V27.6969Z",
                          fill: "#1E1E1E",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_328_2988",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(35.4999 -0.0999952) rotate(90) scale(77.725 793.143)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                    s.jsxs("div", {
                      className:
                        "flex flex-col items-center gap-[.19rem] w-[7.5625rem]",
                      children: [
                        s.jsx("p", {
                          className:
                            "text-white/50 text-[0.5625rem] font-semibold leading-none",
                          children: "NOME",
                        }),
                        s.jsxs("p", {
                          className:
                            "text-primary text-[1.1875rem] font-extrabold leading-none truncate w-full text-center",
                          children: [
                            (n = e[1]) == null ? void 0 : n.name,
                            " #",
                            (r = e[0]) == null ? void 0 : r.id,
                          ],
                        }),
                        s.jsxs("p", {
                          className:
                            "text-white/90 text-xs font-extrabold leading-none truncate w-full text-center",
                          children: [
                            (l = e[1]) == null ? void 0 : l.craft,
                            "X",
                          ],
                        }),
                      ],
                    }),
                  ],
                }),
                s.jsxs("div", {
                  className: "flex flex-col items-center gap-2",
                  children: [
                    s.jsxs("svg", {
                      className: "w-[4.4375rem] h-[4.375rem]",
                      viewBox: "0 0 71 70",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M4.83013 40.5C2.86517 37.0966 2.86516 32.9034 4.83013 29.5L15.4019 11.1891C17.3669 7.7857 20.9983 5.68911 24.9282 5.68911L46.0718 5.68911C50.0017 5.68911 53.6331 7.7857 55.5981 11.1891L66.1699 29.5C68.1348 32.9034 68.1348 37.0966 66.1699 40.5L55.5981 58.8109C53.6331 62.2143 50.0017 64.3109 46.0718 64.3109L24.9282 64.3109C20.9983 64.3109 17.3669 62.2143 15.4019 58.8109L4.83013 40.5Z",
                          fill: "url(#paint0_radial_328_2977)",
                          "fill-opacity": "0.45",
                          stroke: "#FFD600",
                          "stroke-width": "2",
                        }),
                        s.jsx("path", {
                          d: "M10.3868 40C8.60042 36.906 8.60042 33.094 10.3868 30L18.6132 15.7513C20.3996 12.6573 23.7008 10.7513 27.2735 10.7513L43.7265 10.7513C47.2992 10.7513 50.6004 12.6573 52.3868 15.7513L60.6132 30C62.3996 33.094 62.3996 36.906 60.6132 40L52.3868 54.2487C50.6004 57.3427 47.2992 59.2487 43.7265 59.2487L27.2735 59.2487C23.7008 59.2487 20.3996 57.3427 18.6132 54.2487L10.3868 40Z",
                          fill: "#FFD600",
                        }),
                        s.jsx("path", {
                          d: "M36.0084 23.0981C33.6925 23.0981 31.5967 23.2429 30.0558 23.4821C29.2854 23.6017 28.6566 23.7416 28.1833 23.9153C27.9466 24.0021 27.7482 24.0938 27.5755 24.2247C27.4111 24.3495 27.2378 24.5477 27.2216 24.8214H27.1835C27.1835 25.3333 27.2019 25.8382 27.2375 26.3354H25.9219C25.9158 25.9315 25.922 25.5268 25.941 25.123L24.5794 24.804C24.1456 30.221 26.2555 35.4933 30.1384 39.248L30.9334 37.7452C30.7218 37.5699 30.5159 37.3879 30.3161 37.1993C30.6163 36.8856 30.944 36.5993 31.2951 36.344C31.9791 37.0129 32.7263 37.5406 33.52 37.9007C34.643 38.8017 33.929 39.392 32.3267 39.7415C35.3158 40.2798 34.3045 42.9035 31.6094 44.4293C31.5007 44.443 31.3933 44.4558 31.2905 44.4705C30.6787 44.5578 30.1796 44.6589 29.7972 44.7879C29.606 44.8524 29.4439 44.9199 29.2942 45.0243C29.1444 45.1287 28.9577 45.314 28.9577 45.6035C28.9577 45.893 29.1444 46.0768 29.2942 46.1812C29.4439 46.2855 29.606 46.3532 29.7972 46.4177C30.1796 46.5466 30.6788 46.6478 31.2905 46.735C32.514 46.9095 34.174 47.0159 36.0084 47.0159C37.8427 47.0159 39.5027 46.9095 40.7262 46.735C41.3381 46.6478 41.8372 46.5466 42.2196 46.4177C42.4107 46.3532 42.5728 46.2855 42.7225 46.1812C42.8723 46.0769 43.059 45.8931 43.059 45.6036C43.059 45.314 42.8723 45.1287 42.7225 45.0243C42.5728 44.92 42.4108 44.8523 42.2195 44.7879C41.8371 44.6589 41.3379 44.5578 40.7261 44.4705C40.6239 44.4559 40.5169 44.4429 40.4088 44.4292C37.7135 42.9035 36.7022 40.2799 39.6915 39.7415C38.0884 39.3918 37.3743 38.8009 38.4997 37.8992C39.299 37.5361 40.0509 37.0026 40.7388 36.3265C41.0764 36.5688 41.3908 36.8362 41.6767 37.1247C41.4675 37.3378 41.2521 37.5447 41.0308 37.7451L41.8528 39.248C45.8705 35.594 47.7533 30.1312 47.4403 24.7753L46.0518 25.18C46.0747 25.5665 46.0843 25.9514 46.0804 26.3353H44.7807C44.8167 25.8314 44.8347 25.3265 44.8346 24.8213H44.7966C44.7802 24.5476 44.6055 24.3494 44.4411 24.2246C44.2683 24.0936 44.0699 24.0021 43.8332 23.9152C43.36 23.7415 42.7311 23.6015 41.9607 23.482C40.4199 23.2428 38.3241 23.0979 36.0081 23.0979L36.0084 23.0981ZM36.0084 24.0471C38.2845 24.0471 40.3464 24.192 41.8149 24.4199C42.5492 24.5339 43.1382 24.6704 43.5066 24.8056C43.5594 24.825 43.5967 24.8437 43.6399 24.8627C43.5967 24.8817 43.5596 24.9004 43.5066 24.9198C43.1383 25.055 42.5491 25.193 41.8149 25.307C40.3464 25.535 38.2845 25.68 36.0084 25.68C33.7323 25.68 31.6704 25.535 30.2018 25.307C29.4675 25.193 28.8785 25.055 28.5102 24.9198C28.4569 24.9002 28.4203 24.8818 28.3769 24.8627C28.4202 24.8436 28.457 24.8251 28.5102 24.8055C28.8785 24.6703 29.4676 24.5338 30.2019 24.4199C31.6704 24.1919 33.7323 24.0471 36.0084 24.0471ZM25.9918 27.6969H27.3803C27.7895 30.636 28.8139 33.2234 30.2336 35.1237C29.8795 35.4151 29.5528 35.7314 29.2592 36.0727C27.2966 33.7136 26.261 30.7586 25.9918 27.6969ZM44.638 27.6969H46.0091C45.7255 30.7251 44.5995 33.5953 42.7051 35.9648C42.4259 35.6544 42.1229 35.3663 41.799 35.103C43.2113 33.2048 44.2301 30.6254 44.638 27.697V27.6969Z",
                          fill: "#1E1E1E",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_328_2977",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(35.4999 -0.0999952) rotate(90) scale(77.725 793.143)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                    s.jsxs("div", {
                      className:
                        "flex flex-col items-center gap-[.19rem] w-[7.5625rem]",
                      children: [
                        s.jsx("p", {
                          className:
                            "text-white/50 text-[0.5625rem] font-semibold leading-none",
                          children: "NOME",
                        }),
                        s.jsxs("p", {
                          className:
                            "text-primary text-[1.1875rem] font-extrabold leading-none truncate w-full text-center",
                          children: [
                            (i = e[0]) == null ? void 0 : i.name,
                            " #",
                            (o = e[1]) == null ? void 0 : o.id,
                          ],
                        }),
                        s.jsxs("p", {
                          className:
                            "text-white/90 text-xs font-extrabold leading-none truncate w-full text-center",
                          children: [
                            (a = e[0]) == null ? void 0 : a.craft,
                            "X",
                          ],
                        }),
                      ],
                    }),
                  ],
                }),
                s.jsxs("div", {
                  className: "flex flex-col items-center gap-2 self-end",
                  children: [
                    s.jsxs("svg", {
                      className: "w-[4.4375rem] h-[4.375rem]",
                      viewBox: "0 0 71 70",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M4.83013 40.5C2.86517 37.0966 2.86516 32.9034 4.83013 29.5L15.4019 11.1891C17.3669 7.7857 20.9983 5.68911 24.9282 5.68911L46.0718 5.68911C50.0017 5.68911 53.6331 7.7857 55.5981 11.1891L66.1699 29.5C68.1348 32.9034 68.1348 37.0966 66.1699 40.5L55.5981 58.8109C53.6331 62.2143 50.0017 64.3109 46.0718 64.3109L24.9282 64.3109C20.9983 64.3109 17.3669 62.2143 15.4019 58.8109L4.83013 40.5Z",
                          fill: "url(#paint0_radial_328_2966)",
                          "fill-opacity": "0.45",
                          stroke: "#CD886B",
                          "stroke-width": "2",
                        }),
                        s.jsx("path", {
                          d: "M10.3868 40C8.60042 36.906 8.60042 33.094 10.3868 30L18.6132 15.7513C20.3996 12.6573 23.7008 10.7513 27.2735 10.7513L43.7265 10.7513C47.2992 10.7513 50.6004 12.6573 52.3868 15.7513L60.6132 30C62.3996 33.094 62.3996 36.906 60.6132 40L52.3868 54.2487C50.6004 57.3427 47.2992 59.2487 43.7265 59.2487L27.2735 59.2487C23.7008 59.2487 20.3996 57.3427 18.6132 54.2487L10.3868 40Z",
                          fill: "#CD886B",
                        }),
                        s.jsx("path", {
                          d: "M36.0084 23.0981C33.6925 23.0981 31.5967 23.2429 30.0558 23.4821C29.2854 23.6017 28.6566 23.7416 28.1833 23.9153C27.9466 24.0021 27.7482 24.0938 27.5755 24.2247C27.4111 24.3495 27.2378 24.5477 27.2216 24.8214H27.1835C27.1835 25.3333 27.2019 25.8382 27.2375 26.3354H25.9219C25.9158 25.9315 25.922 25.5268 25.941 25.123L24.5794 24.804C24.1456 30.221 26.2555 35.4933 30.1384 39.248L30.9334 37.7452C30.7218 37.5699 30.5159 37.3879 30.3161 37.1993C30.6163 36.8856 30.944 36.5993 31.2951 36.344C31.9791 37.0129 32.7263 37.5406 33.52 37.9007C34.643 38.8017 33.929 39.392 32.3267 39.7415C35.3158 40.2798 34.3045 42.9035 31.6094 44.4293C31.5007 44.443 31.3933 44.4558 31.2905 44.4705C30.6787 44.5578 30.1796 44.6589 29.7972 44.7879C29.606 44.8524 29.4439 44.9199 29.2942 45.0243C29.1444 45.1287 28.9577 45.314 28.9577 45.6035C28.9577 45.893 29.1444 46.0768 29.2942 46.1812C29.4439 46.2855 29.606 46.3532 29.7972 46.4177C30.1796 46.5466 30.6788 46.6478 31.2905 46.735C32.514 46.9095 34.174 47.0159 36.0084 47.0159C37.8427 47.0159 39.5027 46.9095 40.7262 46.735C41.3381 46.6478 41.8372 46.5466 42.2196 46.4177C42.4107 46.3532 42.5728 46.2855 42.7225 46.1812C42.8723 46.0769 43.059 45.8931 43.059 45.6036C43.059 45.314 42.8723 45.1287 42.7225 45.0243C42.5728 44.92 42.4108 44.8523 42.2195 44.7879C41.8371 44.6589 41.3379 44.5578 40.7261 44.4705C40.6239 44.4559 40.5169 44.4429 40.4088 44.4292C37.7135 42.9035 36.7022 40.2799 39.6915 39.7415C38.0884 39.3918 37.3743 38.8009 38.4997 37.8992C39.299 37.5361 40.0509 37.0026 40.7388 36.3265C41.0764 36.5688 41.3908 36.8362 41.6767 37.1247C41.4675 37.3378 41.2521 37.5447 41.0308 37.7451L41.8528 39.248C45.8705 35.594 47.7533 30.1312 47.4403 24.7753L46.0518 25.18C46.0747 25.5665 46.0843 25.9514 46.0804 26.3353H44.7807C44.8167 25.8314 44.8347 25.3265 44.8346 24.8213H44.7966C44.7802 24.5476 44.6055 24.3494 44.4411 24.2246C44.2683 24.0936 44.0699 24.0021 43.8332 23.9152C43.36 23.7415 42.7311 23.6015 41.9607 23.482C40.4199 23.2428 38.3241 23.0979 36.0081 23.0979L36.0084 23.0981ZM36.0084 24.0471C38.2845 24.0471 40.3464 24.192 41.8149 24.4199C42.5492 24.5339 43.1382 24.6704 43.5066 24.8056C43.5594 24.825 43.5967 24.8437 43.6399 24.8627C43.5967 24.8817 43.5596 24.9004 43.5066 24.9198C43.1383 25.055 42.5491 25.193 41.8149 25.307C40.3464 25.535 38.2845 25.68 36.0084 25.68C33.7323 25.68 31.6704 25.535 30.2018 25.307C29.4675 25.193 28.8785 25.055 28.5102 24.9198C28.4569 24.9002 28.4203 24.8818 28.3769 24.8627C28.4202 24.8436 28.457 24.8251 28.5102 24.8055C28.8785 24.6703 29.4676 24.5338 30.2019 24.4199C31.6704 24.1919 33.7323 24.0471 36.0084 24.0471ZM25.9918 27.6969H27.3803C27.7895 30.636 28.8139 33.2234 30.2336 35.1237C29.8795 35.4151 29.5528 35.7314 29.2592 36.0727C27.2966 33.7136 26.261 30.7586 25.9918 27.6969ZM44.638 27.6969H46.0091C45.7255 30.7251 44.5995 33.5953 42.7051 35.9648C42.4259 35.6544 42.1229 35.3663 41.799 35.103C43.2113 33.2048 44.2301 30.6254 44.638 27.697V27.6969Z",
                          fill: "#1E1E1E",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_328_2966",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(35.4999 -0.0999952) rotate(90) scale(77.725 793.143)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                    s.jsxs("div", {
                      className:
                        "flex flex-col items-center gap-[.19rem] w-[7.5625rem]",
                      children: [
                        s.jsx("p", {
                          className:
                            "text-white/50 text-[0.5625rem] font-semibold leading-none",
                          children: "NOME",
                        }),
                        s.jsxs("p", {
                          className:
                            "text-primary text-[1.1875rem] font-extrabold leading-none truncate w-full text-center",
                          children: [
                            (u = e[2]) == null ? void 0 : u.name,
                            " #",
                            (f = e[2]) == null ? void 0 : f.id,
                          ],
                        }),
                        s.jsxs("p", {
                          className:
                            "text-white/90 text-xs font-extrabold leading-none truncate w-full text-center",
                          children: [
                            (c = e[2]) == null ? void 0 : c.craft,
                            "X",
                          ],
                        }),
                      ],
                    }),
                  ],
                }),
              ],
            }),
            s.jsxs("div", {
              className: "flex flex-col gap-4",
              children: [
                s.jsxs("div", {
                  className: "flex items-center",
                  children: [
                    s.jsx("p", {
                      className:
                        "text-white/70 text-[0.6875rem] font-extrabold uppercase w-[4.875rem]",
                      children: "POSIÇÃO",
                    }),
                    s.jsx("p", {
                      className:
                        "text-white/70 text-[0.6875rem] font-extrabold uppercase w-[5.8125rem]",
                      children: "ID",
                    }),
                    s.jsx("p", {
                      className:
                        "text-white/70 text-[0.6875rem] font-extrabold uppercase w-[19rem]",
                      children: "NOME",
                    }),
                    s.jsx("p", {
                      className:
                        "text-white/70 text-[0.6875rem] font-extrabold uppercase w-[8.625rem] text-center",
                      children: "CRAFT",
                    }),
                  ],
                }),
                s.jsx("div", {
                  className: "flex flex-col max-h-[31.125rem] overflow-y-auto",
                  children: e.map((h, v) => s.jsx(M2, { player: h }, v)),
                }),
              ],
            }),
          ],
        }),
      ],
    })
  );
}
const R2 = {},
  Sa = (e) => {
    let t;
    const n = new Set(),
      r = (c, h) => {
        const v = typeof c == "function" ? c(t) : c;
        if (!Object.is(v, t)) {
          const g = t;
          (t =
            h ?? (typeof v != "object" || v === null)
              ? v
              : Object.assign({}, t, v)),
            n.forEach((x) => x(t, g));
        }
      },
      l = () => t,
      u = {
        setState: r,
        getState: l,
        getInitialState: () => f,
        subscribe: (c) => (n.add(c), () => n.delete(c)),
        destroy: () => {
          (R2 ? "production" : void 0) !== "production" &&
            console.warn(
              "[DEPRECATED] The `destroy` method will be unsupported in a future version. Instead use unsubscribe function returned by subscribe. Everything will be garbage-collected if store is garbage-collected."
            ),
            n.clear();
        },
      },
      f = (t = e(r, l, u));
    return u;
  },
  D2 = (e) => (e ? Sa(e) : Sa);
var b1 = { exports: {} },
  e3 = {},
  t3 = { exports: {} },
  n3 = {};
/**
 * @license React
 * use-sync-external-store-shim.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var cn = S;
function O2(e, t) {
  return (e === t && (e !== 0 || 1 / e === 1 / t)) || (e !== e && t !== t);
}
var U2 = typeof Object.is == "function" ? Object.is : O2,
  F2 = cn.useState,
  B2 = cn.useEffect,
  I2 = cn.useLayoutEffect,
  $2 = cn.useDebugValue;
function A2(e, t) {
  var n = t(),
    r = F2({ inst: { value: n, getSnapshot: t } }),
    l = r[0].inst,
    i = r[1];
  return (
    I2(
      function () {
        (l.value = n), (l.getSnapshot = t), si(l) && i({ inst: l });
      },
      [e, n, t]
    ),
    B2(
      function () {
        return (
          si(l) && i({ inst: l }),
          e(function () {
            si(l) && i({ inst: l });
          })
        );
      },
      [e]
    ),
    $2(n),
    n
  );
}
function si(e) {
  var t = e.getSnapshot;
  e = e.value;
  try {
    var n = t();
    return !U2(e, n);
  } catch {
    return !0;
  }
}
function V2(e, t) {
  return t();
}
var H2 =
  typeof window > "u" ||
  typeof window.document > "u" ||
  typeof window.document.createElement > "u"
    ? V2
    : A2;
n3.useSyncExternalStore =
  cn.useSyncExternalStore !== void 0 ? cn.useSyncExternalStore : H2;
t3.exports = n3;
var Z2 = t3.exports;
/**
 * @license React
 * use-sync-external-store-shim/with-selector.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var zl = S,
  W2 = Z2;
function Q2(e, t) {
  return (e === t && (e !== 0 || 1 / e === 1 / t)) || (e !== e && t !== t);
}
var G2 = typeof Object.is == "function" ? Object.is : Q2,
  K2 = W2.useSyncExternalStore,
  Y2 = zl.useRef,
  X2 = zl.useEffect,
  J2 = zl.useMemo,
  q2 = zl.useDebugValue;
e3.useSyncExternalStoreWithSelector = function (e, t, n, r, l) {
  var i = Y2(null);
  if (i.current === null) {
    var o = { hasValue: !1, value: null };
    i.current = o;
  } else o = i.current;
  i = J2(
    function () {
      function u(g) {
        if (!f) {
          if (((f = !0), (c = g), (g = r(g)), l !== void 0 && o.hasValue)) {
            var x = o.value;
            if (l(x, g)) return (h = x);
          }
          return (h = g);
        }
        if (((x = h), G2(c, g))) return x;
        var C = r(g);
        return l !== void 0 && l(x, C) ? x : ((c = g), (h = C));
      }
      var f = !1,
        c,
        h,
        v = n === void 0 ? null : n;
      return [
        function () {
          return u(t());
        },
        v === null
          ? void 0
          : function () {
              return u(v());
            },
      ];
    },
    [t, n, r, l]
  );
  var a = K2(e, i[0], i[1]);
  return (
    X2(
      function () {
        (o.hasValue = !0), (o.value = a);
      },
      [a]
    ),
    q2(a),
    a
  );
};
b1.exports = e3;
var b2 = b1.exports;
const ef = ka(b2),
  r3 = {},
  { useDebugValue: tf } = so,
  { useSyncExternalStoreWithSelector: nf } = ef;
let Ea = !1;
const rf = (e) => e;
function lf(e, t = rf, n) {
  (r3 ? "production" : void 0) !== "production" &&
    n &&
    !Ea &&
    (console.warn(
      "[DEPRECATED] Use `createWithEqualityFn` instead of `create` or use `useStoreWithEqualityFn` instead of `useStore`. They can be imported from 'zustand/traditional'. https://github.com/pmndrs/zustand/discussions/1937"
    ),
    (Ea = !0));
  const r = nf(
    e.subscribe,
    e.getState,
    e.getServerState || e.getInitialState,
    t,
    n
  );
  return tf(r), r;
}
const ja = (e) => {
    (r3 ? "production" : void 0) !== "production" &&
      typeof e != "function" &&
      console.warn(
        "[DEPRECATED] Passing a vanilla store will be unsupported in a future version. Instead use `import { useStore } from 'zustand'`."
      );
    const t = typeof e == "function" ? D2(e) : e,
      n = (r, l) => lf(t, r, l);
    return Object.assign(n, t), n;
  },
  of = (e) => (e ? ja(e) : ja),
  l3 = of((e) => ({
    selectedItem: { time: 0, name: "", image: "", spawn: "", requires: [] },
    setSelectedItem: (t) => e({ selectedItem: t }),
    production: { items: [], inQueue: [] },
    setProduction: (t) => e({ production: t }),
    itemsInQueue: [],
    setItemsInQueue: (t) => e({ itemsInQueue: t }),
    progress: 0,
    setProgress: (t) => e({ progress: t }),
  }));
function sf({ item: e, amount: t, setAmount: n, handleProduceItem: r }) {
  const { selectedItem: l, setSelectedItem: i } = l3();
  return s.jsxs("div", {
    onClick: () => i(e),
    className: zn(
      "cursor-pointer w-[21.25rem] p-2.5 bg-white/[.07] rounded-xl flex flex-col gap-2.5"
    ),
    style: {
      background:
        l.name === e.name
          ? "linear-gradient(280deg, rgba(18, 182, 255, 0.00) 14.01%, rgba(18, 182, 255, 0.50) 109.38%), rgba(255, 255, 255, 0.15)"
          : "",
      boxShadow: "inset 0 0 0 .0625rem rgba(255, 255, 255, 0.25)",
    },
    children: [
      s.jsxs("div", {
        className: "flex items-center gap-4",
        children: [
          s.jsx("div", {
            className:
              "size-20 bg-polygon bg-no-repeat bg-center bg-contain flex-none",
            children: s.jsx("img", {
              draggable: !1,
              src: `http://127.0.0.1/images/${e.image}.png`,
              className: "size-full object-cover",
            }),
          }),
          s.jsxs("div", {
            className: "w-full",
            children: [
              s.jsx("h4", {
                className:
                  "text-primary text-[1.125rem] font-black uppercase truncate w-full",
                children: e.name,
              }),
              s.jsxs("div", {
                className: "flex items-center justify-between",
                children: [
                  s.jsx("p", {
                    className: "text-white/90 text-xs font-bold",
                    children: "Tempo necessário",
                  }),
                  s.jsxs("div", {
                    className: "flex items-center gap-2",
                    children: [
                      s.jsx("svg", {
                        className: "size-[.875rem]",
                        viewBox: "0 0 14 14",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: s.jsx("path", {
                          d: "M0 7C0 3.13385 3.13385 0 7 0C10.8662 0 14 3.13385 14 7C14 10.8662 10.8662 14 7 14C3.13385 14 0 10.8662 0 7ZM7.53846 2.69231C7.53846 2.5495 7.48173 2.41254 7.38075 2.31156C7.27977 2.21058 7.14281 2.15385 7 2.15385C6.85719 2.15385 6.72023 2.21058 6.61925 2.31156C6.51827 2.41254 6.46154 2.5495 6.46154 2.69231V7C6.46154 7.29723 6.70277 7.53846 7 7.53846H10.2308C10.3736 7.53846 10.5105 7.48173 10.6115 7.38075C10.7125 7.27977 10.7692 7.14281 10.7692 7C10.7692 6.85719 10.7125 6.72023 10.6115 6.61925C10.5105 6.51827 10.3736 6.46154 10.2308 6.46154H7.53846V2.69231Z",
                          fill: "white",
                          "fill-opacity": "0.5",
                        }),
                      }),
                      s.jsx("p", {
                        className: "text-white/60 text-xs font-medium",
                        children: new Date(e.time * 1e3)
                          .toISOString()
                          .substr(11, 8),
                      }),
                    ],
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
      l.name === e.name &&
        s.jsxs("div", {
          className: "flex flex-col gap-2.5",
          children: [
            s.jsxs("div", {
              className: "flex items-center gap-[.38rem]",
              children: [
                s.jsx("input", {
                  id: "amount",
                  type: "number",
                  name: "amount",
                  value: t,
                  onChange: (o) => n(Number(o.target.value)),
                  className:
                    "w-[6.25rem] h-8 rounded-[.625rem] border-[.0625rem] border-white/20 bg-white/20 outline-none text-center text-xs font-extrabold placeholder:text-[#D9D9D9] text-white",
                }),
                s.jsx("div", {
                  onClick: () => n(t + 1),
                  className:
                    "size-8 rounded-[.625rem] border-[.0625rem] border-white/20 bg-white/20 flex items-center justify-center",
                  children: s.jsx("svg", {
                    className: "size-[1.375rem]",
                    viewBox: "0 0 22 22",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: s.jsx("path", {
                      d: "M11 4.8125V17.1875M17.1875 11H4.8125",
                      stroke: "white",
                      "stroke-width": "1.2",
                      "stroke-linecap": "round",
                      "stroke-linejoin": "round",
                    }),
                  }),
                }),
                s.jsx("div", {
                  onClick: () => t > 1 && n(t - 1),
                  className:
                    "size-8 rounded-[.625rem] border-[.0625rem] border-white/20 bg-white/20 flex items-center justify-center",
                  children: s.jsx("svg", {
                    className: "size-[1.375rem]",
                    viewBox: "0 0 22 22",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: s.jsx("path", {
                      d: "M17 11H5",
                      stroke: "white",
                      "stroke-width": "1.2",
                      "stroke-linecap": "round",
                      "stroke-linejoin": "round",
                    }),
                  }),
                }),
              ],
            }),
            s.jsx("button", {
              onClick: r,
              className:
                "w-full h-8 bg-primary rounded-lg text-[#1E1E1E] text-xs font-extrabold",
              style: { boxShadow: "0 0 .875rem 0 rgba(18, 182, 255, 0.45)" },
              children: "PRODUZIR",
            }),
          ],
        }),
    ],
  });
}
function af({ item: e, itemsInQueue: t, setItemsInQueue: n }) {
  var o;
  const [r, l] = S.useState(
    ((o = e.production) == null ? void 0 : o.time) || 0
  );
  bo("updateQueue", n);
  function i() {
    Oe("RemoveItemFromQueue", { item: e }, !0).then((a) => {
      if (!a) return;
      const u = t.filter((f) => f.id !== e.id);
      n(u);
    });
  }
  return (
    S.useEffect(() => {
      if (t.length === 0) return;
      const a = setTimeout(() => {
        if (r >= e.time * (e.amount || 1)) {
          clearTimeout(a);
          return;
        }
        l((u) => u + 1);
      }, 1e3);
      return () => clearTimeout(a);
    }, [r]),
    s.jsxs("div", {
      className:
        "w-[21.25rem] p-2.5 rounded-xl bg-white/10 flex flex-col gap-2",
      style: {
        background:
          r === e.time * (e.amount || 1)
            ? "linear-gradient(280deg, rgba(18, 182, 255, 0.00) 14.01%, rgba(18, 182, 255, 0.50) 109.38%), rgba(255, 255, 255, 0.15)"
            : "",
        boxShadow: "inset 0 0 0 .0625rem rgba(255, 255, 255, 0.25)",
      },
      children: [
        s.jsxs("div", {
          className: "flex items-center gap-4",
          children: [
            s.jsx("div", {
              className: "size-20 bg-polygon bg-contain bg-no-repeat bg-center",
              children: s.jsx("img", {
                src: `http://127.0.0.1/images/${e.image}.png`,
                alt: "size-full object-cover",
              }),
            }),
            s.jsxs("div", {
              className: "flex flex-col gap-[.38rem]",
              children: [
                s.jsxs("p", {
                  className:
                    "text-primary text-[1.125rem] font-black leading-none uppercase",
                  children: [e.amount || 1, "X - ", e.name],
                }),
                s.jsxs("div", {
                  className: "flex items-center gap-2",
                  children: [
                    s.jsx("svg", {
                      className: "size-4",
                      viewBox: "0 0 16 16",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: s.jsx("path", {
                        d: "M0 8C0 3.58154 3.58154 0 8 0C12.4185 0 16 3.58154 16 8C16 12.4185 12.4185 16 8 16C3.58154 16 0 12.4185 0 8ZM8.61539 3.07692C8.61539 2.91371 8.55055 2.75719 8.43514 2.64178C8.31974 2.52637 8.16321 2.46154 8 2.46154C7.83679 2.46154 7.68026 2.52637 7.56486 2.64178C7.44945 2.75719 7.38462 2.91371 7.38462 3.07692V8C7.38462 8.33969 7.66031 8.61539 8 8.61539H11.6923C11.8555 8.61539 12.012 8.55055 12.1275 8.43514C12.2429 8.31974 12.3077 8.16321 12.3077 8C12.3077 7.83679 12.2429 7.68026 12.1275 7.56486C12.012 7.44945 11.8555 7.38462 11.6923 7.38462H8.61539V3.07692Z",
                        fill: "white",
                        "fill-opacity": "0.5",
                      }),
                    }),
                    s.jsx("p", {
                      className: "text-white/90 text-[0.8125rem] font-bold",
                      children: new Date(
                        (r
                          ? e.time * (e.amount || 1) - r
                          : e.time * (e.amount || 1)) * 1e3
                      )
                        .toISOString()
                        .substr(11, 8),
                    }),
                  ],
                }),
              ],
            }),
          ],
        }),
        s.jsx("div", {
          className:
            "w-full h-[0.1875rem] bg-white/10 rounded-[0.1875rem] overflow-hidden",
          children: s.jsx("div", {
            className: "h-full bg-primary rounded-[0.1875rem] duration-300",
            style: {
              width: `${
                100 -
                ((r ? e.time * (e.amount || 1) - r : e.time * (e.amount || 1)) /
                  (e.time * (e.amount || 1))) *
                  100
              }%`,
            },
          }),
        }),
        r === e.time * (e.amount || 1) &&
          s.jsx("button", {
            onClick: i,
            className:
              "w-full h-8 bg-primary rounded-lg text-[#1E1E1E] text-xs font-extrabold",
            style: { boxShadow: "0 0 .875rem 0 rgba(18, 182, 255, 0.45)" },
            children: "RESGATAR",
          }),
      ],
    })
  );
}
function uf() {
  var x, C, j, p, d, m, y, E, _, N, z, I;
  const [e, t] = S.useState(1),
    [n, r] = S.useState(""),
    [l, i] = S.useState([]),
    [o, a] = S.useState([]),
    {
      production: u,
      setProduction: f,
      selectedItem: c,
      setSelectedItem: h,
    } = l3(),
    v = S.useMemo(
      () =>
        u.items.filter((P) => P.name.toLowerCase().includes(n.toLowerCase())),
      [n, u.items]
    );
  function g() {
    const P = Math.floor(Math.random() * 1e6);
    Oe("ProduceItem", { item: { ...c, id: P }, amount: e }, P).then((J) => {
      J && a((yt) => [...yt, { ...c, amount: e, id: P }]);
    });
  }
  return (
    S.useEffect(() => {
      Oe(
        "GetProductions",
        {},
        {
          items: [
            {
              name: "Aluminio",
              image: "aluminio",
              spawn: "aluminio",
              time: 20,
              requires: [
                {
                  spawn: "aluminio",
                  amount: 2,
                  name: "asdas",
                  image: "aluminio",
                },
                {
                  spawn: "aluminio",
                  amount: 2,
                  name: "asdas",
                  image: "aluminio",
                },
                {
                  spawn: "aluminio",
                  amount: 2,
                  name: "asdas",
                  image: "aluminio",
                },
              ],
            },
            {
              name: "Energetico",
              image: "energetico",
              spawn: "aluminio",
              time: 1,
              requires: [],
            },
          ],
          inQueue: [
            {
              id: 12,
              name: "Aluminio",
              image: "aluminio",
              spawn: "aluminio",
              time: 20,
              requires: [],
              amount: 2,
              production: { time: 35 },
            },
            {
              id: 24,
              name: "Maconha",
              image: "maconha",
              spawn: "maconha",
              time: 20,
              requires: [],
              amount: 8,
              production: { time: 20 },
            },
          ],
        }
      ).then((P) => {
        f(P), h(P.items[0]), a(P.inQueue);
      }),
        Oe("GetStorage", {}, [
          { name: "Gatilhos", image: "AMMO_PISTOL_MK2", amount: 33223 },
          { name: "Aluminio", image: "aluminio", amount: 33223 },
          { name: "Maconha", image: "maconha", amount: 33223 },
        ]).then((P) => {
          i(P);
        });
    }, []),
    S.useEffect(() => {
      t(1);
    }, [c]),
    s.jsxs("div", {
      className:
        "w-screen h-screen bg-background bg-cover bg-no-repeat bg-center flex items-center justify-between",
      children: [
        s.jsxs("div", {
          className:
            "h-screen flex flex-col gap-5 pl-10 pt-[3.75rem] border-r-[.0625rem] border-white/20 pr-10",
          children: [
            s.jsxs("div", {
              children: [
                s.jsx("p", {
                  className:
                    "text-white text-[1.0625rem] font-extrabold leading-none",
                  children: "LISTA DE",
                }),
                s.jsx("h2", {
                  className:
                    "text-primary text-[1.625rem] font-black leading-none",
                  children: "FABRICAVEIS",
                }),
              ],
            }),
            s.jsxs("div", {
              className: "flex flex-col gap-[.81rem] h-[calc(100vh-1.75rem)]",
              children: [
                s.jsxs("div", {
                  className:
                    "flex items-center gap-1 px-2.5 h-8 w-full rounded-lg border-[.0625rem] border-white/20 bg-white/5",
                  children: [
                    s.jsxs("svg", {
                      className: "size-4",
                      viewBox: "0 0 16 16",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M7.18016 12.1999C6.1873 12.1999 5.21673 11.9055 4.3912 11.3539C3.56566 10.8023 2.92224 10.0183 2.54228 9.10099C2.16233 8.1837 2.06292 7.17435 2.25662 6.20056C2.45031 5.22678 2.92842 4.3323 3.63048 3.63024C4.33254 2.92818 5.22702 2.45007 6.20081 2.25637C7.17459 2.06267 8.18394 2.16209 9.10123 2.54204C10.0185 2.92199 10.8025 3.56542 11.3541 4.39095C11.9057 5.21649 12.2002 6.18705 12.2002 7.17991C12.2002 7.83915 12.0703 8.49193 11.818 9.10099C11.5658 9.71004 11.196 10.2634 10.7298 10.7296C10.2637 11.1957 9.71028 11.5655 9.10123 11.8178C8.49218 12.0701 7.83939 12.1999 7.18016 12.1999ZM7.18016 3.16658C6.38903 3.16658 5.61567 3.40118 4.95788 3.8407C4.30008 4.28023 3.78739 4.90494 3.48464 5.63585C3.18189 6.36675 3.10268 7.17102 3.25702 7.94694C3.41136 8.72287 3.79232 9.4356 4.35173 9.99501C4.91114 10.5544 5.62387 10.9354 6.3998 11.0897C7.17572 11.2441 7.97999 11.1649 8.71089 10.8621C9.4418 10.5593 10.0665 10.0467 10.506 9.38886C10.9456 8.73107 11.1802 7.95771 11.1802 7.16658C11.1802 6.10572 10.7587 5.0883 10.0086 4.33815C9.25844 3.58801 8.24102 3.16658 7.18016 3.16658Z",
                          fill: "#CCCCCC",
                          "fill-opacity": "0.8",
                        }),
                        s.jsx("path", {
                          d: "M13.3331 13.8334C13.2675 13.8337 13.2024 13.8209 13.1417 13.7957C13.081 13.7705 13.026 13.7335 12.9798 13.6867L10.2265 10.9334C10.1382 10.8386 10.0901 10.7132 10.0924 10.5837C10.0946 10.4542 10.1471 10.3306 10.2387 10.239C10.3303 10.1474 10.4539 10.0949 10.5835 10.0926C10.713 10.0903 10.8384 10.1384 10.9331 10.2267L13.6865 12.9801C13.7801 13.0738 13.8327 13.2009 13.8327 13.3334C13.8327 13.4659 13.7801 13.593 13.6865 13.6867C13.6403 13.7335 13.5853 13.7705 13.5246 13.7957C13.4639 13.8209 13.3988 13.8337 13.3331 13.8334Z",
                          fill: "#CCCCCC",
                          "fill-opacity": "0.8",
                        }),
                      ],
                    }),
                    s.jsx("input", {
                      type: "text",
                      placeholder: "Pesquisar...",
                      onChange: (P) => r(P.target.value),
                      className:
                        "bg-transparent text-white text-[0.6875rem] font-semibold outline-none border-none flex-1 uppercase placeholder:text-[#D9D9D9CC]",
                    }),
                  ],
                }),
                s.jsx("div", {
                  className: "flex flex-col gap-2.5 overflow-y-auto h-full",
                  children:
                    v == null
                      ? void 0
                      : v.map((P, J) =>
                          s.jsx(
                            sf,
                            {
                              item: P,
                              amount: e,
                              setAmount: t,
                              handleProduceItem: g,
                            },
                            J
                          )
                        ),
                }),
              ],
            }),
          ],
        }),
        s.jsxs("div", {
          className: "flex-1 h-full flex flex-col items-center pt-5 gap-5",
          children: [
            s.jsx(rs, {}),
            s.jsxs("div", {
              children: [
                s.jsxs("div", {
                  className: "flex flex-col items-center",
                  children: [
                    s.jsx("p", {
                      className: "text-white text-xs font-bold leading-none",
                      children: "CRAFT",
                    }),
                    s.jsx("h1", {
                      className:
                        "text-primary text-[3.125rem] font-black uppercase leading-none",
                      style: {
                        textShadow: "0 0 .875rem rgba(18, 182, 255, 0.45)",
                      },
                      children: c == null ? void 0 : c.name,
                    }),
                  ],
                }),
                s.jsxs("div", {
                  className:
                    "size-[32rem] bg-center-details bg-cover bg-no-repeat bg-center flex items-center justify-center relative",
                  children: [
                    s.jsx("img", {
                      src: `http://127.0.0.1/images/${
                        c == null ? void 0 : c.image
                      }.png`,
                      className:
                        "size-full object-contain absolute top-1/2 -translate-y-1/2 left-1/2 -translate-x-1/2",
                    }),
                    s.jsx("button", {
                      onClick: g,
                      className:
                        "w-[12.5rem] h-8 bg-primary rounded-lg text-[#1E1E1E] text-xs font-extrabold z-20",
                      style: {
                        boxShadow: "0 0 .875rem 0 rgba(18, 182, 255, 0.45)",
                      },
                      children: "PRODUZIR",
                    }),
                  ],
                }),
              ],
            }),
            s.jsxs("div", {
              className: "flex flex-col items-center gap-[.38rem]",
              children: [
                s.jsxs("div", {
                  className: "flex items-center gap-2",
                  children: [
                    s.jsx("svg", {
                      className: "size-[1.1875rem]",
                      viewBox: "0 0 19 19",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: s.jsx("path", {
                        d: "M0 9.5C0 4.25308 4.25308 0 9.5 0C14.7469 0 19 4.25308 19 9.5C19 14.7469 14.7469 19 9.5 19C4.25308 19 0 14.7469 0 9.5ZM10.2308 3.65385C10.2308 3.46003 10.1538 3.27416 10.0167 3.13711C9.87969 3.00007 9.69381 2.92308 9.5 2.92308C9.30619 2.92308 9.12031 3.00007 8.98327 3.13711C8.84622 3.27416 8.76923 3.46003 8.76923 3.65385V9.5C8.76923 9.90338 9.09662 10.2308 9.5 10.2308H13.8846C14.0784 10.2308 14.2643 10.1538 14.4013 10.0167C14.5384 9.87969 14.6154 9.69381 14.6154 9.5C14.6154 9.30619 14.5384 9.12031 14.4013 8.98327C14.2643 8.84622 14.0784 8.76923 13.8846 8.76923H10.2308V3.65385Z",
                        fill: "white",
                      }),
                    }),
                    s.jsx("p", {
                      className: "text-white text-[1.0625rem] font-bold",
                      children: new Date(c.time * e * 1e3)
                        .toISOString()
                        .substr(11, 8),
                    }),
                  ],
                }),
                s.jsxs("div", {
                  className: "flex items-center gap-[.44rem]",
                  children: [
                    s.jsxs("svg", {
                      onClick: () => e > 1 && t(e - 1),
                      className: "size-[3.125rem]",
                      viewBox: "0 0 50 50",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M3.4641 29C2.03504 26.5248 2.03504 23.4752 3.4641 21L10.7679 8.34937C12.197 5.87416 14.838 4.34937 17.6961 4.34937L32.3039 4.34937C35.162 4.34937 37.803 5.87416 39.2321 8.34937L46.5359 21C47.965 23.4752 47.965 26.5248 46.5359 29L39.2321 41.6506C37.803 44.1258 35.162 45.6506 32.3039 45.6506L17.6962 45.6506C14.838 45.6506 12.197 44.1258 10.7679 41.6506L3.4641 29Z",
                          fill: "url(#paint0_radial_325_698)",
                          "fill-opacity": "0.45",
                          stroke: "#12B6FF",
                          "stroke-width": "2",
                        }),
                        s.jsx("path", {
                          d: "M7.02072 28.5C5.7703 26.3342 5.7703 23.6658 7.02072 21.5L12.9793 11.1795C14.2297 9.01368 16.5406 7.67949 19.0415 7.67949L30.9585 7.67949C33.4594 7.67949 35.7703 9.01368 37.0207 11.1795L42.9793 21.5C44.2297 23.6658 44.2297 26.3342 42.9793 28.5L37.0207 38.8205C35.7703 40.9863 33.4594 42.3205 30.9585 42.3205L19.0415 42.3205C16.5406 42.3205 14.2297 40.9863 12.9793 38.8205L7.02072 28.5Z",
                          fill: "#12B6FF",
                        }),
                        s.jsx("path", {
                          d: "M32.8569 24.2142H17.1426C16.9343 24.2142 16.7344 24.297 16.5871 24.4444C16.4397 24.5917 16.3569 24.7916 16.3569 24.9999C16.3569 25.2083 16.4397 25.4082 16.5871 25.5555C16.7344 25.7029 16.9343 25.7857 17.1426 25.7857H32.8569C33.0653 25.7857 33.2652 25.7029 33.4125 25.5555C33.5599 25.4082 33.6426 25.2083 33.6426 24.9999C33.6426 24.7916 33.5599 24.5917 33.4125 24.4444C33.2652 24.297 33.0653 24.2142 32.8569 24.2142Z",
                          fill: "black",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_325_698",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(25 -0.0714213) rotate(90) scale(55.5179 566.531)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                    s.jsx("input", {
                      type: "number",
                      placeholder: "0",
                      value: e,
                      onChange: (P) => t(Number(P.target.value)),
                      className:
                        "w-[8.5rem] h-8 rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/15 text-center outline-none text-sm font-bold text-[#D9D9D9]",
                    }),
                    s.jsxs("svg", {
                      onClick: () => t(e + 1),
                      className: "size-[3.125rem]",
                      viewBox: "0 0 50 50",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M3.4641 29C2.03504 26.5248 2.03504 23.4752 3.4641 21L10.7679 8.34937C12.197 5.87416 14.838 4.34937 17.6961 4.34937L32.3039 4.34937C35.162 4.34937 37.803 5.87416 39.2321 8.34937L46.5359 21C47.965 23.4752 47.965 26.5248 46.5359 29L39.2321 41.6506C37.803 44.1258 35.162 45.6506 32.3039 45.6506L17.6962 45.6506C14.838 45.6506 12.197 44.1258 10.7679 41.6506L3.4641 29Z",
                          fill: "url(#paint0_radial_325_688)",
                          "fill-opacity": "0.45",
                          stroke: "#12B6FF",
                          "stroke-width": "2",
                        }),
                        s.jsx("path", {
                          d: "M7.02072 28.5C5.7703 26.3342 5.7703 23.6658 7.02072 21.5L12.9793 11.1795C14.2297 9.01368 16.5406 7.67949 19.0415 7.67949L30.9585 7.67949C33.4594 7.67949 35.7703 9.01368 37.0207 11.1795L42.9793 21.5C44.2297 23.6658 44.2297 26.3342 42.9793 28.5L37.0207 38.8205C35.7703 40.9863 33.4594 42.3205 30.9585 42.3205L19.0415 42.3205C16.5406 42.3205 14.2297 40.9863 12.9793 38.8205L7.02072 28.5Z",
                          fill: "#12B6FF",
                        }),
                        s.jsx("path", {
                          d: "M32.8569 24.2143H25.7855V17.1429C25.7855 16.9345 25.7027 16.7347 25.5554 16.5873C25.408 16.44 25.2082 16.3572 24.9998 16.3572C24.7914 16.3572 24.5916 16.44 24.4442 16.5873C24.2969 16.7347 24.2141 16.9345 24.2141 17.1429V24.2143H17.1426C16.9343 24.2143 16.7344 24.2971 16.5871 24.4444C16.4397 24.5918 16.3569 24.7916 16.3569 25C16.3569 25.2084 16.4397 25.4083 16.5871 25.5556C16.7344 25.703 16.9343 25.7857 17.1426 25.7857H24.2141V32.8572C24.2141 33.0656 24.2969 33.2654 24.4442 33.4128C24.5916 33.5601 24.7914 33.6429 24.9998 33.6429C25.2082 33.6429 25.408 33.5601 25.5554 33.4128C25.7027 33.2654 25.7855 33.0656 25.7855 32.8572V25.7857H32.8569C33.0653 25.7857 33.2652 25.703 33.4125 25.5556C33.5599 25.4083 33.6426 25.2084 33.6426 25C33.6426 24.7916 33.5599 24.5918 33.4125 24.4444C33.2652 24.2971 33.0653 24.2143 32.8569 24.2143Z",
                          fill: "black",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_325_688",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(25 -0.0714213) rotate(90) scale(55.5179 566.531)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                  ],
                }),
              ],
            }),
            s.jsxs("div", {
              className: "w-[18.375rem] h-[13.3125rem] relative flex-none",
              children: [
                s.jsxs("div", {
                  className:
                    "size-[6.875rem] absolute top-1/2 -translate-y-1/2 left-0 flex items-center justify-center",
                  children: [
                    (c == null ? void 0 : c.requires[0]) &&
                      s.jsxs("div", {
                        className: "flex flex-col items-center gap-2",
                        children: [
                          s.jsxs("p", {
                            className: "text-white/60 text-xs font-medium",
                            children: [
                              ((x = c == null ? void 0 : c.requires[0]) == null
                                ? void 0
                                : x.amount) * e,
                              "x",
                            ],
                          }),
                          s.jsx("img", {
                            src: `http://127.0.0.1/images/${
                              (C = c == null ? void 0 : c.requires[0]) == null
                                ? void 0
                                : C.image
                            }.png`,
                            className: "size-[2.25rem] object-contain",
                          }),
                          s.jsx("p", {
                            className: "text-white text-xs font-bold",
                            children:
                              (j = c == null ? void 0 : c.requires[0]) == null
                                ? void 0
                                : j.name,
                          }),
                        ],
                      }),
                    s.jsxs("svg", {
                      className:
                        "size-full absolute top-1/2 -translate-y-1/2 left-1/2 -translate-x-1/2",
                      viewBox: "0 0 110 110",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M3.4641 61C1.32051 57.2872 1.32051 52.7128 3.4641 49L24.0359 13.3686C26.1795 9.65578 30.141 7.36859 34.4282 7.36859L75.5718 7.36859C79.859 7.36859 83.8205 9.65577 85.9641 13.3686L106.536 49C108.679 52.7128 108.679 57.2872 106.536 61L85.9641 96.6314C83.8205 100.344 79.859 102.631 75.5718 102.631L34.4282 102.631C30.141 102.631 26.1795 100.344 24.0359 96.6314L3.4641 61Z",
                          fill: "url(#paint0_radial_323_171)",
                          "fill-opacity": "0.45",
                        }),
                        s.jsx("path", {
                          d: "M4.33013 60.5C2.36516 57.0966 2.36516 52.9034 4.33012 49.5L24.9019 13.8686C26.8669 10.4652 30.4983 8.36859 34.4282 8.36859L75.5718 8.36859C79.5017 8.36859 83.1331 10.4652 85.0981 13.8686L105.67 49.5C107.635 52.9034 107.635 57.0966 105.67 60.5L85.0981 96.1314C83.1331 99.5348 79.5017 101.631 75.5718 101.631L34.4282 101.631C30.4983 101.631 26.8669 99.5348 24.9019 96.1314L4.33013 60.5Z",
                          stroke: "#DDDDDD",
                          "stroke-opacity": "0.5",
                          "stroke-width": "2",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_323_171",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(54.9999 -0.157143) rotate(90) scale(122.139 1246.37)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                  ],
                }),
                s.jsxs("div", {
                  className:
                    "size-[6.875rem] absolute top-1/2 -translate-y-1/2 right-0 flex items-center justify-center",
                  children: [
                    (c == null ? void 0 : c.requires[1]) &&
                      s.jsxs("div", {
                        className: "flex flex-col items-center gap-2",
                        children: [
                          s.jsxs("p", {
                            className: "text-white/60 text-xs font-medium",
                            children: [
                              ((p = c == null ? void 0 : c.requires[1]) == null
                                ? void 0
                                : p.amount) * e,
                              "x",
                            ],
                          }),
                          s.jsx("img", {
                            src: `http://127.0.0.1/images/${
                              (d = c == null ? void 0 : c.requires[1]) == null
                                ? void 0
                                : d.image
                            }.png`,
                            className: "size-[2.25rem] object-contain",
                          }),
                          s.jsx("p", {
                            className: "text-white text-xs font-bold",
                            children:
                              (m = c == null ? void 0 : c.requires[1]) == null
                                ? void 0
                                : m.name,
                          }),
                        ],
                      }),
                    s.jsxs("svg", {
                      className:
                        "size-full absolute top-1/2 -translate-y-1/2 left-1/2 -translate-x-1/2",
                      viewBox: "0 0 110 110",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M3.4641 61C1.32051 57.2872 1.32051 52.7128 3.4641 49L24.0359 13.3686C26.1795 9.65578 30.141 7.36859 34.4282 7.36859L75.5718 7.36859C79.859 7.36859 83.8205 9.65577 85.9641 13.3686L106.536 49C108.679 52.7128 108.679 57.2872 106.536 61L85.9641 96.6314C83.8205 100.344 79.859 102.631 75.5718 102.631L34.4282 102.631C30.141 102.631 26.1795 100.344 24.0359 96.6314L3.4641 61Z",
                          fill: "url(#paint0_radial_323_171)",
                          "fill-opacity": "0.45",
                        }),
                        s.jsx("path", {
                          d: "M4.33013 60.5C2.36516 57.0966 2.36516 52.9034 4.33012 49.5L24.9019 13.8686C26.8669 10.4652 30.4983 8.36859 34.4282 8.36859L75.5718 8.36859C79.5017 8.36859 83.1331 10.4652 85.0981 13.8686L105.67 49.5C107.635 52.9034 107.635 57.0966 105.67 60.5L85.0981 96.1314C83.1331 99.5348 79.5017 101.631 75.5718 101.631L34.4282 101.631C30.4983 101.631 26.8669 99.5348 24.9019 96.1314L4.33013 60.5Z",
                          stroke: "#DDDDDD",
                          "stroke-opacity": "0.5",
                          "stroke-width": "2",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_323_171",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(54.9999 -0.157143) rotate(90) scale(122.139 1246.37)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                  ],
                }),
                s.jsxs("div", {
                  className:
                    "size-[6.875rem] absolute top-0 left-1/2 -translate-x-1/2 flex items-center justify-center",
                  children: [
                    (c == null ? void 0 : c.requires[2]) &&
                      s.jsxs("div", {
                        className: "flex flex-col items-center gap-2",
                        children: [
                          s.jsxs("p", {
                            className: "text-white/60 text-xs font-medium",
                            children: [
                              ((y = c == null ? void 0 : c.requires[2]) == null
                                ? void 0
                                : y.amount) * e,
                              "x",
                            ],
                          }),
                          s.jsx("img", {
                            src: `http://127.0.0.1/images/${
                              (E = c == null ? void 0 : c.requires[2]) == null
                                ? void 0
                                : E.image
                            }.png`,
                            className: "size-[2.25rem] object-contain",
                          }),
                          s.jsx("p", {
                            className: "text-white text-xs font-bold",
                            children:
                              (_ = c == null ? void 0 : c.requires[2]) == null
                                ? void 0
                                : _.name,
                          }),
                        ],
                      }),
                    s.jsxs("svg", {
                      className:
                        "size-full absolute top-1/2 -translate-y-1/2 left-1/2 -translate-x-1/2",
                      viewBox: "0 0 110 110",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M3.4641 61C1.32051 57.2872 1.32051 52.7128 3.4641 49L24.0359 13.3686C26.1795 9.65578 30.141 7.36859 34.4282 7.36859L75.5718 7.36859C79.859 7.36859 83.8205 9.65577 85.9641 13.3686L106.536 49C108.679 52.7128 108.679 57.2872 106.536 61L85.9641 96.6314C83.8205 100.344 79.859 102.631 75.5718 102.631L34.4282 102.631C30.141 102.631 26.1795 100.344 24.0359 96.6314L3.4641 61Z",
                          fill: "url(#paint0_radial_323_171)",
                          "fill-opacity": "0.45",
                        }),
                        s.jsx("path", {
                          d: "M4.33013 60.5C2.36516 57.0966 2.36516 52.9034 4.33012 49.5L24.9019 13.8686C26.8669 10.4652 30.4983 8.36859 34.4282 8.36859L75.5718 8.36859C79.5017 8.36859 83.1331 10.4652 85.0981 13.8686L105.67 49.5C107.635 52.9034 107.635 57.0966 105.67 60.5L85.0981 96.1314C83.1331 99.5348 79.5017 101.631 75.5718 101.631L34.4282 101.631C30.4983 101.631 26.8669 99.5348 24.9019 96.1314L4.33013 60.5Z",
                          stroke: "#DDDDDD",
                          "stroke-opacity": "0.5",
                          "stroke-width": "2",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_323_171",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(54.9999 -0.157143) rotate(90) scale(122.139 1246.37)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                  ],
                }),
                s.jsxs("div", {
                  className:
                    "size-[6.875rem] absolute bottom-0 left-1/2 -translate-x-1/2 flex items-center justify-center",
                  children: [
                    (c == null ? void 0 : c.requires[3]) &&
                      s.jsxs("div", {
                        className: "flex flex-col items-center gap-2",
                        children: [
                          s.jsxs("p", {
                            className: "text-white/60 text-xs font-medium",
                            children: [
                              ((N = c == null ? void 0 : c.requires[3]) == null
                                ? void 0
                                : N.amount) * e,
                              "x",
                            ],
                          }),
                          s.jsx("img", {
                            src: `http://127.0.0.1/images/${
                              (z = c == null ? void 0 : c.requires[3]) == null
                                ? void 0
                                : z.image
                            }.png`,
                            className: "size-[2.25rem] object-contain",
                          }),
                          s.jsx("p", {
                            className: "text-white text-xs font-bold",
                            children:
                              (I = c == null ? void 0 : c.requires[3]) == null
                                ? void 0
                                : I.name,
                          }),
                        ],
                      }),
                    s.jsxs("svg", {
                      className:
                        "size-full absolute top-1/2 -translate-y-1/2 left-1/2 -translate-x-1/2",
                      viewBox: "0 0 110 110",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M3.4641 61C1.32051 57.2872 1.32051 52.7128 3.4641 49L24.0359 13.3686C26.1795 9.65578 30.141 7.36859 34.4282 7.36859L75.5718 7.36859C79.859 7.36859 83.8205 9.65577 85.9641 13.3686L106.536 49C108.679 52.7128 108.679 57.2872 106.536 61L85.9641 96.6314C83.8205 100.344 79.859 102.631 75.5718 102.631L34.4282 102.631C30.141 102.631 26.1795 100.344 24.0359 96.6314L3.4641 61Z",
                          fill: "url(#paint0_radial_323_171)",
                          "fill-opacity": "0.45",
                        }),
                        s.jsx("path", {
                          d: "M4.33013 60.5C2.36516 57.0966 2.36516 52.9034 4.33012 49.5L24.9019 13.8686C26.8669 10.4652 30.4983 8.36859 34.4282 8.36859L75.5718 8.36859C79.5017 8.36859 83.1331 10.4652 85.0981 13.8686L105.67 49.5C107.635 52.9034 107.635 57.0966 105.67 60.5L85.0981 96.1314C83.1331 99.5348 79.5017 101.631 75.5718 101.631L34.4282 101.631C30.4983 101.631 26.8669 99.5348 24.9019 96.1314L4.33013 60.5Z",
                          stroke: "#DDDDDD",
                          "stroke-opacity": "0.5",
                          "stroke-width": "2",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_323_171",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(54.9999 -0.157143) rotate(90) scale(122.139 1246.37)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                  ],
                }),
              ],
            }),
          ],
        }),
        s.jsxs("div", {
          className:
            "h-screen flex flex-col gap-5 pr-10 pt-[3.75rem] pb-10 border-l-[.0625rem] border-white/20 pl-10",
          children: [
            s.jsxs("div", {
              children: [
                s.jsx("p", {
                  className: "text-white text-[1.0625rem] font-extrabold",
                  children: "LISTA EM",
                }),
                s.jsx("h2", {
                  className: "text-primary text-[1.625rem] font-black",
                  children: "FABRICAÇÃO",
                }),
              ],
            }),
            s.jsx("div", {
              className:
                "w-[21.25rem] flex flex-col gap-2.5 overflow-y-auto h-full",
              children: o.map((P, J) =>
                s.jsx(
                  af,
                  { item: P, itemsInQueue: o, setItemsInQueue: a },
                  P.id
                )
              ),
            }),
            s.jsxs("div", {
              className: "flex flex-col gap-1.5",
              children: [
                s.jsx("h3", {
                  className: "text-primary text-[3.125rem] font-black",
                  children: "ARMAZEM",
                }),
                s.jsx("hr", {
                  className:
                    "h-[0.1875rem] w-full bg-white/10 border-none flex-none",
                }),
                s.jsxs("div", {
                  className: "flex items-center gap-[1.88rem]",
                  children: [
                    s.jsxs("svg", {
                      className: "size-[5rem]",
                      viewBox: "0 0 80 80",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        s.jsx("path", {
                          d: "M4.33013 45.5C2.36516 42.0966 2.36516 37.9034 4.33012 34.5L17.4019 11.859C19.3669 8.45557 22.9983 6.35898 26.9282 6.35898L53.0718 6.35898C57.0017 6.35898 60.6331 8.45556 62.5981 11.859L75.6699 34.5C77.6348 37.9034 77.6348 42.0966 75.6699 45.5L62.5981 68.141C60.6331 71.5444 57.0017 73.641 53.0718 73.641L26.9282 73.641C22.9983 73.641 19.3669 71.5444 17.4019 68.141L4.33013 45.5Z",
                          fill: "url(#paint0_radial_1030_2)",
                          "fill-opacity": "0.45",
                          stroke: "#12B6FF",
                          "stroke-width": "2",
                        }),
                        s.jsx("path", {
                          d: "M36 47C36.5304 47 37.0391 46.7893 37.4142 46.4142C37.7893 46.0391 38 45.5304 38 45V37C38 35.9391 37.5786 34.9217 36.8284 34.1716C36.0783 33.4214 35.0609 33 34 33M34 33C32.9391 33 31.9217 33.4214 31.1716 34.1716C30.4214 34.9217 30 35.9391 30 37V45C30 45.5304 30.2107 46.0391 30.5858 46.4142C30.9609 46.7893 31.4696 47 32 47H48C48.5304 47 49.0391 46.7893 49.4142 46.4142C49.7893 46.0391 50 45.5304 50 45V37C50 35.9391 49.5786 34.9217 48.8284 34.1716C48.0783 33.4214 47.0609 33 46 33H34ZM30 39H50M44 39V42",
                          stroke: "#12B6FF",
                          "stroke-width": "2",
                          "stroke-linecap": "round",
                          "stroke-linejoin": "round",
                        }),
                        s.jsx("defs", {
                          children: s.jsxs("radialGradient", {
                            id: "paint0_radial_1030_2",
                            cx: "0",
                            cy: "0",
                            r: "1",
                            gradientUnits: "userSpaceOnUse",
                            gradientTransform:
                              "translate(39.9999 -0.11428) rotate(90) scale(88.8286 906.449)",
                            children: [
                              s.jsx("stop", {}),
                              s.jsx("stop", {
                                offset: "1",
                                "stop-opacity": "0",
                              }),
                            ],
                          }),
                        }),
                      ],
                    }),
                    s.jsx("div", {
                      className: "flex flex-col gap-1",
                      children: l.map((P, J) =>
                        s.jsxs(
                          "div",
                          {
                            className: "flex items-center gap-[0.625rem]",
                            children: [
                              s.jsxs("p", {
                                className:
                                  "text-white/90 text-[0.8125rem] font-bold uppercase",
                                children: [P.name, ":"],
                              }),
                              s.jsxs("p", {
                                className:
                                  "text-white/90 text-[0.8125rem] font-bold",
                                children: [P.amount, "x"],
                              }),
                            ],
                          },
                          J
                        )
                      ),
                    }),
                  ],
                }),
                s.jsx("hr", {
                  className:
                    "h-[0.1875rem] w-full bg-white/10 border-none flex-none",
                }),
              ],
            }),
          ],
        }),
      ],
    })
  );
}
function cf() {
  const e = ns(),
    { setOpened: t } = N2();
  function n() {
    Oe("selectedFarm", null, !0).then(() => t(!1));
  }
  function r() {
    Oe("selectedDrugs", null, !0).then(() => t(!1));
  }
  function l() {
    e("/craft");
  }
  return s.jsx("div", {
    className:
      "w-screen h-screen bg-background bg-center bg-no-repeat bg-cover flex items-center justify-center",
    children: s.jsxs("div", {
      className: "flex flex-col items-center gap-2.5",
      children: [
        s.jsxs("div", {
          className: "flex flex-col items-center",
          children: [
            s.jsxs("svg", {
              className: "size-[4.125rem] mb-2.5",
              viewBox: "0 0 66 66",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: [
                s.jsx("path", {
                  d: "M4.33013 38.5C2.36517 35.0966 2.36516 30.9034 4.33013 27.5L13.9019 10.9212C15.8669 7.51775 19.4983 5.42116 23.4282 5.42116L42.5718 5.42116C46.5017 5.42116 50.1331 7.51775 52.0981 10.9212L61.6699 27.5C63.6348 30.9034 63.6348 35.0966 61.6699 38.5L52.0981 55.0788C50.1331 58.4822 46.5017 60.5788 42.5718 60.5788L23.4282 60.5788C19.4983 60.5788 15.8669 58.4822 13.9019 55.0788L4.33013 38.5Z",
                  fill: "url(#paint0_radial_279_3971)",
                  "fill-opacity": "0.45",
                  stroke: "#12B6FF",
                  "stroke-width": "2",
                }),
                s.jsx("path", {
                  d: "M7.88675 38C6.10042 34.906 6.10042 31.094 7.88675 28L16.1132 13.7513C17.8996 10.6573 21.2008 8.75129 24.7735 8.75129L41.2265 8.75129C44.7992 8.75129 48.1004 10.6573 49.8868 13.7513L58.1132 28C59.8996 31.094 59.8996 34.906 58.1132 38L49.8868 52.2487C48.1004 55.3427 44.7992 57.2487 41.2265 57.2487L24.7735 57.2487C21.2008 57.2487 17.8996 55.3427 16.1132 52.2487L7.88675 38Z",
                  fill: "#12B6FF",
                }),
                s.jsx("path", {
                  d: "M33 20.066C32.7909 20.1564 32.6043 20.3598 32.5252 20.5688C32.48 20.6761 32.463 22.2352 32.463 25.4211V30.1097L32.593 30.0758C32.6609 30.0532 32.8643 30.008 33.0396 29.9685L33.3674 29.9007L33.3787 25.681C33.3957 21.5234 33.3957 21.4613 33.5143 21.3088C33.5765 21.224 33.7009 21.0998 33.7857 21.0376C33.9383 20.919 33.9778 20.919 39.2457 20.919C44.5135 20.919 44.553 20.919 44.7057 21.0376C44.7904 21.0998 44.9148 21.224 44.977 21.3088L45.0957 21.4613L45.1239 43.4975L45.3104 43.4637C45.5252 43.4241 45.723 43.2885 45.8813 43.0682L46 42.9157V20.5575L45.8813 20.4049C45.8191 20.3202 45.6948 20.1959 45.61 20.1338C45.4574 20.0152 45.4178 20.0152 39.3135 20.0039C34.2774 19.9926 33.1413 20.0039 33 20.066Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M34.2717 30.2001L34.4696 30.347L34.6674 30.4995L35.1761 30.0137L35.1987 29.3641C35.2326 28.2399 35.5943 27.4152 36.3857 26.6187C36.8943 26.1103 37.3748 25.8109 38.0474 25.5906C38.4261 25.4663 38.5787 25.4437 39.2457 25.4494C39.9183 25.4494 40.0596 25.4663 40.4609 25.5963C41.1109 25.8109 41.5857 26.1103 42.1 26.6244C42.6143 27.1384 42.9139 27.6129 43.1287 28.2625C43.2587 28.6636 43.2757 28.8048 43.2757 29.477C43.2757 30.1493 43.2587 30.2905 43.1287 30.6915C43.0439 30.9401 42.8857 31.3073 42.767 31.5106C42.49 31.9795 41.7496 32.7195 41.2804 32.9963C40.2348 33.6007 38.9291 33.7024 37.7817 33.2561L37.3635 33.098L36.7078 33.7137C36.3461 34.047 35.9109 34.4706 35.7413 34.6458L35.4304 34.9621L35.7413 34.8096C36.0013 34.674 36.1257 34.6514 36.5043 34.6458C36.8887 34.6458 37.0074 34.6684 37.2787 34.8039C37.9004 35.109 38.3074 35.7529 38.313 36.4534C38.313 36.6681 38.2961 36.9166 38.2678 37.0013L38.2283 37.1595H44.2196V21.7946H34.2717V30.2001Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M38.5957 26.3815C38.443 26.4097 38.1096 26.534 37.8552 26.6526C36.9396 27.0932 36.2726 28.0027 36.1257 29.0138C36.0861 29.268 36.0691 29.4827 36.0861 29.494C36.0974 29.5053 36.2161 29.5053 36.3517 29.4883C36.5891 29.4657 36.6174 29.4375 37.1374 28.7935L37.6743 28.1213H40.817L41.5687 29.059C42.4222 30.1267 42.4504 30.1323 42.3939 29.3132C42.3204 28.1383 41.6591 27.1441 40.6417 26.6526C39.9635 26.3306 39.3135 26.2459 38.5957 26.3815Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M37.7987 29.4036L37.5104 29.7708L37.7535 29.9967C37.8891 30.121 38.07 30.3696 38.1548 30.5447C38.2904 30.8158 38.313 30.9288 38.3074 31.3412C38.3074 31.7253 38.2791 31.8778 38.1717 32.0925C38.0135 32.4258 38.0191 32.4258 38.6183 32.5613C39.353 32.7251 40.2009 32.5839 40.8961 32.1716C41.207 31.9908 41.727 31.4767 41.8739 31.2112L41.9757 31.0135L41.19 30.025L40.4043 29.0308H38.087L37.7987 29.4036Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M27.9413 30.4712C27.7209 30.5673 26.7657 31.5219 26.24 32.1772C24.8778 33.8662 24.3239 35.3801 24.3239 37.3911V38.0464L26.1383 39.8653L27.9526 41.6786H29.2357C29.9365 41.6786 30.7335 41.6504 30.9935 41.6221C32.3443 41.4527 33.5596 40.9217 34.4809 40.0913C34.95 39.6676 37.29 37.0635 37.3691 36.8771C37.6291 36.25 37.0922 35.4648 36.4478 35.5383C36.3065 35.5496 36.1313 35.6061 36.0578 35.6569C35.9787 35.7021 35.5661 36.1314 35.1365 36.6059C33.5257 38.3853 33.4804 38.4249 32.8135 38.4926C32.3387 38.5435 32.1917 38.4926 32.09 38.261C31.9713 37.9786 31.9826 37.1821 32.1126 36.9336C32.1635 36.8262 33.2939 35.7021 34.69 34.3633C36.0578 33.0584 37.2222 31.923 37.2843 31.8383C37.3465 31.7592 37.4087 31.5671 37.42 31.4146C37.4822 30.7141 36.7643 30.1888 36.1143 30.4599C36.0126 30.4995 35.5604 30.8836 35.1139 31.3129L34.3 32.0812L34.2661 31.7761C34.2209 31.3694 34.0457 31.0983 33.7404 30.9514C33.2713 30.7198 32.9491 30.8158 32.3896 31.3412L32.0109 31.6914V31.4146C32.0109 30.6746 31.3326 30.1888 30.6826 30.4656C30.5696 30.5108 30.2135 30.8045 29.8913 31.1209L29.2978 31.697V31.4146C29.2978 30.6689 28.6026 30.1831 27.9413 30.4712Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M22.8261 38.4023L22.2609 38.9671L22.843 39.5433L23.4196 40.1252L24.2674 39.2778L23.8435 38.8542C23.4422 38.4475 23.4252 38.4192 23.4083 38.1311L23.3913 37.8317L22.8261 38.4023Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M37.8891 43.4862H38.7935V38.0633H37.8891V43.4862Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M39.6978 43.4862H40.6022V38.0633H39.6978V43.4862Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M41.5065 43.4862H42.4109V38.0633H41.5065V43.4862Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M43.3152 43.4862H44.2196V38.0633H43.3152V43.4862Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M36.51 39.2609L36.0804 39.7297V43.4862H36.9848V41.142C36.9848 39.854 36.9735 38.7977 36.9622 38.7977C36.9509 38.7977 36.7474 39.0067 36.51 39.2609Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M24.0696 40.7748L25.2283 41.9328L26.0761 41.0855L24.9174 39.9275L24.0696 40.7748Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M21.0174 41.1137L20 42.1305L23.8717 46L24.9004 44.9663L25.9348 43.9382L24.013 42.0175C22.9561 40.9612 22.08 40.0969 22.063 40.0969C22.0461 40.0969 21.577 40.5545 21.0174 41.1137Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M34.7126 41.0685L34.2717 41.4188V43.4862H35.1761V42.1023C35.1761 41.3397 35.1704 40.7183 35.1648 40.7183C35.1535 40.7183 34.95 40.8765 34.7126 41.0685Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M25.8783 42.5824L27.037 43.7404L27.6135 43.1586L28.1957 42.5824H27.5739L26.7261 41.7351L25.8783 42.5824Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("path", {
                  d: "M32.9717 42.0514C32.8022 42.1192 32.6157 42.1927 32.5535 42.2096C32.463 42.2322 32.4517 42.2774 32.4743 42.5824C32.5083 43.0569 32.7683 43.3846 33.1865 43.4637L33.3674 43.4975V42.7011C33.3674 42.2661 33.3504 41.9102 33.3278 41.9102C33.2996 41.9159 33.1413 41.978 32.9717 42.0514Z",
                  fill: "#1E1E1E",
                }),
                s.jsx("defs", {
                  children: s.jsxs("radialGradient", {
                    id: "paint0_radial_279_3971",
                    cx: "0",
                    cy: "0",
                    r: "1",
                    gradientUnits: "userSpaceOnUse",
                    gradientTransform:
                      "translate(32.9999 -0.0942811) rotate(90) scale(73.2836 747.82)",
                    children: [
                      s.jsx("stop", {}),
                      s.jsx("stop", { offset: "1", "stop-opacity": "0" }),
                    ],
                  }),
                }),
              ],
            }),
            s.jsx("p", {
              className:
                "text-[#EBEBEB] text-[1.1875rem] font-extrabold leading-none",
              children: "ESCOLHER",
            }),
            s.jsx("h2", {
              className: "text-primary text-[1.875rem] font-black leading-none",
              children: "SUA ROTA",
            }),
          ],
        }),
        s.jsxs("div", {
          className: "flex flex-col gap-[.44rem]",
          children: [
            s.jsx("button", {
              onClick: l,
              className:
                "w-[15.625rem] h-8 rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/15 text-white/80 text-xs font-extrabold hover:bg-primary hover:text-[#1E1E1E] duration-300",
              children: "CRAFT",
            }),
            s.jsx("button", {
              onClick: n,
              className:
                "w-[15.625rem] h-8 rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/15 text-white/80 text-xs font-extrabold hover:bg-primary hover:text-[#1E1E1E] duration-300",
              children: "ROTA FARM",
            }),
            s.jsx("button", {
              onClick: r,
              className:
                "w-[15.625rem] h-8 rounded-[0.5625rem] border-[.0625rem] border-white/20 bg-white/15 text-white/80 text-xs font-extrabold hover:bg-primary hover:text-[#1E1E1E] duration-300",
              children: "ROTA DROGA",
            }),
          ],
        }),
      ],
    }),
  });
}
ai.createRoot(document.getElementById("root")).render(
  s.jsx(so.StrictMode, {
    children: s.jsx(L2, {
      children: s.jsx(_2, {
        children: s.jsxs(E2, {
          children: [
            s.jsx(Pn, { path: "*", element: s.jsx(cf, {}) }),
            s.jsx(Pn, { path: "/craft", element: s.jsx(uf, {}) }),
            s.jsx(Pn, { path: "/storage", element: s.jsx(z2, {}) }),
            s.jsx(Pn, { path: "/ranking", element: s.jsx(T2, {}) }),
          ],
        }),
      }),
    }),
  })
);
