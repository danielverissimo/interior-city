function Eu(r, s) {
  for (var a = 0; a < s.length; a++) {
    const c = s[a];
    if (typeof c != "string" && !Array.isArray(c)) {
      for (const d in c)
        if (d !== "default" && !(d in r)) {
          const m = Object.getOwnPropertyDescriptor(c, d);
          m &&
            Object.defineProperty(
              r,
              d,
              m.get ? m : { enumerable: !0, get: () => c[d] },
            );
        }
    }
  }
  return Object.freeze(
    Object.defineProperty(r, Symbol.toStringTag, { value: "Module" }),
  );
}
(function () {
  const s = document.createElement("link").relList;
  if (s && s.supports && s.supports("modulepreload")) return;
  for (const d of document.querySelectorAll('link[rel="modulepreload"]')) c(d);
  new MutationObserver((d) => {
    for (const m of d)
      if (m.type === "childList")
        for (const x of m.addedNodes)
          x.tagName === "LINK" && x.rel === "modulepreload" && c(x);
  }).observe(document, { childList: !0, subtree: !0 });
  function a(d) {
    const m = {};
    return (
      d.integrity && (m.integrity = d.integrity),
      d.referrerPolicy && (m.referrerPolicy = d.referrerPolicy),
      d.crossOrigin === "use-credentials"
        ? (m.credentials = "include")
        : d.crossOrigin === "anonymous"
          ? (m.credentials = "omit")
          : (m.credentials = "same-origin"),
      m
    );
  }
  function c(d) {
    if (d.ep) return;
    d.ep = !0;
    const m = a(d);
    fetch(d.href, m);
  }
})();
function vl(r) {
  return r && r.__esModule && Object.prototype.hasOwnProperty.call(r, "default")
    ? r.default
    : r;
}
var v0 = { exports: {} },
  Gr = {},
  g0 = { exports: {} },
  le = {};
/**
 * @license React
 * react.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var $2;
function Su() {
  if ($2) return le;
  $2 = 1;
  var r = Symbol.for("react.element"),
    s = Symbol.for("react.portal"),
    a = Symbol.for("react.fragment"),
    c = Symbol.for("react.strict_mode"),
    d = Symbol.for("react.profiler"),
    m = Symbol.for("react.provider"),
    x = Symbol.for("react.context"),
    h = Symbol.for("react.forward_ref"),
    v = Symbol.for("react.suspense"),
    y = Symbol.for("react.memo"),
    M = Symbol.for("react.lazy"),
    j = Symbol.iterator;
  function b(L) {
    return L === null || typeof L != "object"
      ? null
      : ((L = (j && L[j]) || L["@@iterator"]),
        typeof L == "function" ? L : null);
  }
  var O = {
      isMounted: function () {
        return !1;
      },
      enqueueForceUpdate: function () {},
      enqueueReplaceState: function () {},
      enqueueSetState: function () {},
    },
    H = Object.assign,
    N = {};
  function k(L, I, re) {
    ((this.props = L),
      (this.context = I),
      (this.refs = N),
      (this.updater = re || O));
  }
  ((k.prototype.isReactComponent = {}),
    (k.prototype.setState = function (L, I) {
      if (typeof L != "object" && typeof L != "function" && L != null)
        throw Error(
          "setState(...): takes an object of state variables to update or a function which returns an object of state variables.",
        );
      this.updater.enqueueSetState(this, L, I, "setState");
    }),
    (k.prototype.forceUpdate = function (L) {
      this.updater.enqueueForceUpdate(this, L, "forceUpdate");
    }));
  function P() {}
  P.prototype = k.prototype;
  function T(L, I, re) {
    ((this.props = L),
      (this.context = I),
      (this.refs = N),
      (this.updater = re || O));
  }
  var V = (T.prototype = new P());
  ((V.constructor = T), H(V, k.prototype), (V.isPureReactComponent = !0));
  var Z = Array.isArray,
    ee = Object.prototype.hasOwnProperty,
    K = { current: null },
    Y = { key: !0, ref: !0, __self: !0, __source: !0 };
  function de(L, I, re) {
    var ie,
      ae = {},
      ue = null,
      he = null;
    if (I != null)
      for (ie in (I.ref !== void 0 && (he = I.ref),
      I.key !== void 0 && (ue = "" + I.key),
      I))
        ee.call(I, ie) && !Y.hasOwnProperty(ie) && (ae[ie] = I[ie]);
    var fe = arguments.length - 2;
    if (fe === 1) ae.children = re;
    else if (1 < fe) {
      for (var ge = Array(fe), tt = 0; tt < fe; tt++)
        ge[tt] = arguments[tt + 2];
      ae.children = ge;
    }
    if (L && L.defaultProps)
      for (ie in ((fe = L.defaultProps), fe))
        ae[ie] === void 0 && (ae[ie] = fe[ie]);
    return {
      $$typeof: r,
      type: L,
      key: ue,
      ref: he,
      props: ae,
      _owner: K.current,
    };
  }
  function Pe(L, I) {
    return {
      $$typeof: r,
      type: L.type,
      key: I,
      ref: L.ref,
      props: L.props,
      _owner: L._owner,
    };
  }
  function Ae(L) {
    return typeof L == "object" && L !== null && L.$$typeof === r;
  }
  function st(L) {
    var I = { "=": "=0", ":": "=2" };
    return (
      "$" +
      L.replace(/[=:]/g, function (re) {
        return I[re];
      })
    );
  }
  var Oe = /\/+/g;
  function Le(L, I) {
    return typeof L == "object" && L !== null && L.key != null
      ? st("" + L.key)
      : I.toString(36);
  }
  function et(L, I, re, ie, ae) {
    var ue = typeof L;
    (ue === "undefined" || ue === "boolean") && (L = null);
    var he = !1;
    if (L === null) he = !0;
    else
      switch (ue) {
        case "string":
        case "number":
          he = !0;
          break;
        case "object":
          switch (L.$$typeof) {
            case r:
            case s:
              he = !0;
          }
      }
    if (he)
      return (
        (he = L),
        (ae = ae(he)),
        (L = ie === "" ? "." + Le(he, 0) : ie),
        Z(ae)
          ? ((re = ""),
            L != null && (re = L.replace(Oe, "$&/") + "/"),
            et(ae, I, re, "", function (tt) {
              return tt;
            }))
          : ae != null &&
            (Ae(ae) &&
              (ae = Pe(
                ae,
                re +
                  (!ae.key || (he && he.key === ae.key)
                    ? ""
                    : ("" + ae.key).replace(Oe, "$&/") + "/") +
                  L,
              )),
            I.push(ae)),
        1
      );
    if (((he = 0), (ie = ie === "" ? "." : ie + ":"), Z(L)))
      for (var fe = 0; fe < L.length; fe++) {
        ue = L[fe];
        var ge = ie + Le(ue, fe);
        he += et(ue, I, re, ge, ae);
      }
    else if (((ge = b(L)), typeof ge == "function"))
      for (L = ge.call(L), fe = 0; !(ue = L.next()).done; )
        ((ue = ue.value),
          (ge = ie + Le(ue, fe++)),
          (he += et(ue, I, re, ge, ae)));
    else if (ue === "object")
      throw (
        (I = String(L)),
        Error(
          "Objects are not valid as a React child (found: " +
            (I === "[object Object]"
              ? "object with keys {" + Object.keys(L).join(", ") + "}"
              : I) +
            "). If you meant to render a collection of children, use an array instead.",
        )
      );
    return he;
  }
  function ot(L, I, re) {
    if (L == null) return L;
    var ie = [],
      ae = 0;
    return (
      et(L, ie, "", "", function (ue) {
        return I.call(re, ue, ae++);
      }),
      ie
    );
  }
  function Be(L) {
    if (L._status === -1) {
      var I = L._result;
      ((I = I()),
        I.then(
          function (re) {
            (L._status === 0 || L._status === -1) &&
              ((L._status = 1), (L._result = re));
          },
          function (re) {
            (L._status === 0 || L._status === -1) &&
              ((L._status = 2), (L._result = re));
          },
        ),
        L._status === -1 && ((L._status = 0), (L._result = I)));
    }
    if (L._status === 1) return L._result.default;
    throw L._result;
  }
  var xe = { current: null },
    F = { transition: null },
    q = {
      ReactCurrentDispatcher: xe,
      ReactCurrentBatchConfig: F,
      ReactCurrentOwner: K,
    };
  function W() {
    throw Error("act(...) is not supported in production builds of React.");
  }
  return (
    (le.Children = {
      map: ot,
      forEach: function (L, I, re) {
        ot(
          L,
          function () {
            I.apply(this, arguments);
          },
          re,
        );
      },
      count: function (L) {
        var I = 0;
        return (
          ot(L, function () {
            I++;
          }),
          I
        );
      },
      toArray: function (L) {
        return (
          ot(L, function (I) {
            return I;
          }) || []
        );
      },
      only: function (L) {
        if (!Ae(L))
          throw Error(
            "React.Children.only expected to receive a single React element child.",
          );
        return L;
      },
    }),
    (le.Component = k),
    (le.Fragment = a),
    (le.Profiler = d),
    (le.PureComponent = T),
    (le.StrictMode = c),
    (le.Suspense = v),
    (le.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = q),
    (le.act = W),
    (le.cloneElement = function (L, I, re) {
      if (L == null)
        throw Error(
          "React.cloneElement(...): The argument must be a React element, but you passed " +
            L +
            ".",
        );
      var ie = H({}, L.props),
        ae = L.key,
        ue = L.ref,
        he = L._owner;
      if (I != null) {
        if (
          (I.ref !== void 0 && ((ue = I.ref), (he = K.current)),
          I.key !== void 0 && (ae = "" + I.key),
          L.type && L.type.defaultProps)
        )
          var fe = L.type.defaultProps;
        for (ge in I)
          ee.call(I, ge) &&
            !Y.hasOwnProperty(ge) &&
            (ie[ge] = I[ge] === void 0 && fe !== void 0 ? fe[ge] : I[ge]);
      }
      var ge = arguments.length - 2;
      if (ge === 1) ie.children = re;
      else if (1 < ge) {
        fe = Array(ge);
        for (var tt = 0; tt < ge; tt++) fe[tt] = arguments[tt + 2];
        ie.children = fe;
      }
      return {
        $$typeof: r,
        type: L.type,
        key: ae,
        ref: ue,
        props: ie,
        _owner: he,
      };
    }),
    (le.createContext = function (L) {
      return (
        (L = {
          $$typeof: x,
          _currentValue: L,
          _currentValue2: L,
          _threadCount: 0,
          Provider: null,
          Consumer: null,
          _defaultValue: null,
          _globalName: null,
        }),
        (L.Provider = { $$typeof: m, _context: L }),
        (L.Consumer = L)
      );
    }),
    (le.createElement = de),
    (le.createFactory = function (L) {
      var I = de.bind(null, L);
      return ((I.type = L), I);
    }),
    (le.createRef = function () {
      return { current: null };
    }),
    (le.forwardRef = function (L) {
      return { $$typeof: h, render: L };
    }),
    (le.isValidElement = Ae),
    (le.lazy = function (L) {
      return { $$typeof: M, _payload: { _status: -1, _result: L }, _init: Be };
    }),
    (le.memo = function (L, I) {
      return { $$typeof: y, type: L, compare: I === void 0 ? null : I };
    }),
    (le.startTransition = function (L) {
      var I = F.transition;
      F.transition = {};
      try {
        L();
      } finally {
        F.transition = I;
      }
    }),
    (le.unstable_act = W),
    (le.useCallback = function (L, I) {
      return xe.current.useCallback(L, I);
    }),
    (le.useContext = function (L) {
      return xe.current.useContext(L);
    }),
    (le.useDebugValue = function () {}),
    (le.useDeferredValue = function (L) {
      return xe.current.useDeferredValue(L);
    }),
    (le.useEffect = function (L, I) {
      return xe.current.useEffect(L, I);
    }),
    (le.useId = function () {
      return xe.current.useId();
    }),
    (le.useImperativeHandle = function (L, I, re) {
      return xe.current.useImperativeHandle(L, I, re);
    }),
    (le.useInsertionEffect = function (L, I) {
      return xe.current.useInsertionEffect(L, I);
    }),
    (le.useLayoutEffect = function (L, I) {
      return xe.current.useLayoutEffect(L, I);
    }),
    (le.useMemo = function (L, I) {
      return xe.current.useMemo(L, I);
    }),
    (le.useReducer = function (L, I, re) {
      return xe.current.useReducer(L, I, re);
    }),
    (le.useRef = function (L) {
      return xe.current.useRef(L);
    }),
    (le.useState = function (L) {
      return xe.current.useState(L);
    }),
    (le.useSyncExternalStore = function (L, I, re) {
      return xe.current.useSyncExternalStore(L, I, re);
    }),
    (le.useTransition = function () {
      return xe.current.useTransition();
    }),
    (le.version = "18.3.1"),
    le
  );
}
var G2;
function Yr() {
  return (G2 || ((G2 = 1), (g0.exports = Su())), g0.exports);
}
/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var Q2;
function ku() {
  if (Q2) return Gr;
  Q2 = 1;
  var r = Yr(),
    s = Symbol.for("react.element"),
    a = Symbol.for("react.fragment"),
    c = Object.prototype.hasOwnProperty,
    d = r.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner,
    m = { key: !0, ref: !0, __self: !0, __source: !0 };
  function x(h, v, y) {
    var M,
      j = {},
      b = null,
      O = null;
    (y !== void 0 && (b = "" + y),
      v.key !== void 0 && (b = "" + v.key),
      v.ref !== void 0 && (O = v.ref));
    for (M in v) c.call(v, M) && !m.hasOwnProperty(M) && (j[M] = v[M]);
    if (h && h.defaultProps)
      for (M in ((v = h.defaultProps), v)) j[M] === void 0 && (j[M] = v[M]);
    return {
      $$typeof: s,
      type: h,
      key: b,
      ref: O,
      props: j,
      _owner: d.current,
    };
  }
  return ((Gr.Fragment = a), (Gr.jsx = x), (Gr.jsxs = x), Gr);
}
var K2;
function Ru() {
  return (K2 || ((K2 = 1), (v0.exports = ku())), v0.exports);
}
var i = Ru(),
  p = Yr();
const z0 = vl(p),
  _a = Eu({ __proto__: null, default: z0 }, [p]);
var ol = {},
  w0 = { exports: {} },
  Je = {},
  y0 = { exports: {} },
  j0 = {};
/**
 * @license React
 * scheduler.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var Y2;
function Mu() {
  return (
    Y2 ||
      ((Y2 = 1),
      (function (r) {
        function s(F, q) {
          var W = F.length;
          F.push(q);
          e: for (; 0 < W; ) {
            var L = (W - 1) >>> 1,
              I = F[L];
            if (0 < d(I, q)) ((F[L] = q), (F[W] = I), (W = L));
            else break e;
          }
        }
        function a(F) {
          return F.length === 0 ? null : F[0];
        }
        function c(F) {
          if (F.length === 0) return null;
          var q = F[0],
            W = F.pop();
          if (W !== q) {
            F[0] = W;
            e: for (var L = 0, I = F.length, re = I >>> 1; L < re; ) {
              var ie = 2 * (L + 1) - 1,
                ae = F[ie],
                ue = ie + 1,
                he = F[ue];
              if (0 > d(ae, W))
                ue < I && 0 > d(he, ae)
                  ? ((F[L] = he), (F[ue] = W), (L = ue))
                  : ((F[L] = ae), (F[ie] = W), (L = ie));
              else if (ue < I && 0 > d(he, W))
                ((F[L] = he), (F[ue] = W), (L = ue));
              else break e;
            }
          }
          return q;
        }
        function d(F, q) {
          var W = F.sortIndex - q.sortIndex;
          return W !== 0 ? W : F.id - q.id;
        }
        if (
          typeof performance == "object" &&
          typeof performance.now == "function"
        ) {
          var m = performance;
          r.unstable_now = function () {
            return m.now();
          };
        } else {
          var x = Date,
            h = x.now();
          r.unstable_now = function () {
            return x.now() - h;
          };
        }
        var v = [],
          y = [],
          M = 1,
          j = null,
          b = 3,
          O = !1,
          H = !1,
          N = !1,
          k = typeof setTimeout == "function" ? setTimeout : null,
          P = typeof clearTimeout == "function" ? clearTimeout : null,
          T = typeof setImmediate < "u" ? setImmediate : null;
        typeof navigator < "u" &&
          navigator.scheduling !== void 0 &&
          navigator.scheduling.isInputPending !== void 0 &&
          navigator.scheduling.isInputPending.bind(navigator.scheduling);
        function V(F) {
          for (var q = a(y); q !== null; ) {
            if (q.callback === null) c(y);
            else if (q.startTime <= F)
              (c(y), (q.sortIndex = q.expirationTime), s(v, q));
            else break;
            q = a(y);
          }
        }
        function Z(F) {
          if (((N = !1), V(F), !H))
            if (a(v) !== null) ((H = !0), Be(ee));
            else {
              var q = a(y);
              q !== null && xe(Z, q.startTime - F);
            }
        }
        function ee(F, q) {
          ((H = !1), N && ((N = !1), P(de), (de = -1)), (O = !0));
          var W = b;
          try {
            for (
              V(q), j = a(v);
              j !== null && (!(j.expirationTime > q) || (F && !st()));

            ) {
              var L = j.callback;
              if (typeof L == "function") {
                ((j.callback = null), (b = j.priorityLevel));
                var I = L(j.expirationTime <= q);
                ((q = r.unstable_now()),
                  typeof I == "function"
                    ? (j.callback = I)
                    : j === a(v) && c(v),
                  V(q));
              } else c(v);
              j = a(v);
            }
            if (j !== null) var re = !0;
            else {
              var ie = a(y);
              (ie !== null && xe(Z, ie.startTime - q), (re = !1));
            }
            return re;
          } finally {
            ((j = null), (b = W), (O = !1));
          }
        }
        var K = !1,
          Y = null,
          de = -1,
          Pe = 5,
          Ae = -1;
        function st() {
          return !(r.unstable_now() - Ae < Pe);
        }
        function Oe() {
          if (Y !== null) {
            var F = r.unstable_now();
            Ae = F;
            var q = !0;
            try {
              q = Y(!0, F);
            } finally {
              q ? Le() : ((K = !1), (Y = null));
            }
          } else K = !1;
        }
        var Le;
        if (typeof T == "function")
          Le = function () {
            T(Oe);
          };
        else if (typeof MessageChannel < "u") {
          var et = new MessageChannel(),
            ot = et.port2;
          ((et.port1.onmessage = Oe),
            (Le = function () {
              ot.postMessage(null);
            }));
        } else
          Le = function () {
            k(Oe, 0);
          };
        function Be(F) {
          ((Y = F), K || ((K = !0), Le()));
        }
        function xe(F, q) {
          de = k(function () {
            F(r.unstable_now());
          }, q);
        }
        ((r.unstable_IdlePriority = 5),
          (r.unstable_ImmediatePriority = 1),
          (r.unstable_LowPriority = 4),
          (r.unstable_NormalPriority = 3),
          (r.unstable_Profiling = null),
          (r.unstable_UserBlockingPriority = 2),
          (r.unstable_cancelCallback = function (F) {
            F.callback = null;
          }),
          (r.unstable_continueExecution = function () {
            H || O || ((H = !0), Be(ee));
          }),
          (r.unstable_forceFrameRate = function (F) {
            0 > F || 125 < F
              ? console.error(
                  "forceFrameRate takes a positive int between 0 and 125, forcing frame rates higher than 125 fps is not supported",
                )
              : (Pe = 0 < F ? Math.floor(1e3 / F) : 5);
          }),
          (r.unstable_getCurrentPriorityLevel = function () {
            return b;
          }),
          (r.unstable_getFirstCallbackNode = function () {
            return a(v);
          }),
          (r.unstable_next = function (F) {
            switch (b) {
              case 1:
              case 2:
              case 3:
                var q = 3;
                break;
              default:
                q = b;
            }
            var W = b;
            b = q;
            try {
              return F();
            } finally {
              b = W;
            }
          }),
          (r.unstable_pauseExecution = function () {}),
          (r.unstable_requestPaint = function () {}),
          (r.unstable_runWithPriority = function (F, q) {
            switch (F) {
              case 1:
              case 2:
              case 3:
              case 4:
              case 5:
                break;
              default:
                F = 3;
            }
            var W = b;
            b = F;
            try {
              return q();
            } finally {
              b = W;
            }
          }),
          (r.unstable_scheduleCallback = function (F, q, W) {
            var L = r.unstable_now();
            switch (
              (typeof W == "object" && W !== null
                ? ((W = W.delay),
                  (W = typeof W == "number" && 0 < W ? L + W : L))
                : (W = L),
              F)
            ) {
              case 1:
                var I = -1;
                break;
              case 2:
                I = 250;
                break;
              case 5:
                I = 1073741823;
                break;
              case 4:
                I = 1e4;
                break;
              default:
                I = 5e3;
            }
            return (
              (I = W + I),
              (F = {
                id: M++,
                callback: q,
                priorityLevel: F,
                startTime: W,
                expirationTime: I,
                sortIndex: -1,
              }),
              W > L
                ? ((F.sortIndex = W),
                  s(y, F),
                  a(v) === null &&
                    F === a(y) &&
                    (N ? (P(de), (de = -1)) : (N = !0), xe(Z, W - L)))
                : ((F.sortIndex = I), s(v, F), H || O || ((H = !0), Be(ee))),
              F
            );
          }),
          (r.unstable_shouldYield = st),
          (r.unstable_wrapCallback = function (F) {
            var q = b;
            return function () {
              var W = b;
              b = q;
              try {
                return F.apply(this, arguments);
              } finally {
                b = W;
              }
            };
          }));
      })(j0)),
    j0
  );
}
var X2;
function bu() {
  return (X2 || ((X2 = 1), (y0.exports = Mu())), y0.exports);
}
/**
 * @license React
 * react-dom.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var J2;
function Pu() {
  if (J2) return Je;
  J2 = 1;
  var r = Yr(),
    s = bu();
  function a(e) {
    for (
      var t = "https://reactjs.org/docs/error-decoder.html?invariant=" + e,
        n = 1;
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
  var c = new Set(),
    d = {};
  function m(e, t) {
    (x(e, t), x(e + "Capture", t));
  }
  function x(e, t) {
    for (d[e] = t, e = 0; e < t.length; e++) c.add(t[e]);
  }
  var h = !(
      typeof window > "u" ||
      typeof window.document > "u" ||
      typeof window.document.createElement > "u"
    ),
    v = Object.prototype.hasOwnProperty,
    y =
      /^[:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD][:A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\-.0-9\u00B7\u0300-\u036F\u203F-\u2040]*$/,
    M = {},
    j = {};
  function b(e) {
    return v.call(j, e)
      ? !0
      : v.call(M, e)
        ? !1
        : y.test(e)
          ? (j[e] = !0)
          : ((M[e] = !0), !1);
  }
  function O(e, t, n, l) {
    if (n !== null && n.type === 0) return !1;
    switch (typeof t) {
      case "function":
      case "symbol":
        return !0;
      case "boolean":
        return l
          ? !1
          : n !== null
            ? !n.acceptsBooleans
            : ((e = e.toLowerCase().slice(0, 5)),
              e !== "data-" && e !== "aria-");
      default:
        return !1;
    }
  }
  function H(e, t, n, l) {
    if (t === null || typeof t > "u" || O(e, t, n, l)) return !0;
    if (l) return !1;
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
  function N(e, t, n, l, o, u, f) {
    ((this.acceptsBooleans = t === 2 || t === 3 || t === 4),
      (this.attributeName = l),
      (this.attributeNamespace = o),
      (this.mustUseProperty = n),
      (this.propertyName = e),
      (this.type = t),
      (this.sanitizeURL = u),
      (this.removeEmptyString = f));
  }
  var k = {};
  ("children dangerouslySetInnerHTML defaultValue defaultChecked innerHTML suppressContentEditableWarning suppressHydrationWarning style"
    .split(" ")
    .forEach(function (e) {
      k[e] = new N(e, 0, !1, e, null, !1, !1);
    }),
    [
      ["acceptCharset", "accept-charset"],
      ["className", "class"],
      ["htmlFor", "for"],
      ["httpEquiv", "http-equiv"],
    ].forEach(function (e) {
      var t = e[0];
      k[t] = new N(t, 1, !1, e[1], null, !1, !1);
    }),
    ["contentEditable", "draggable", "spellCheck", "value"].forEach(
      function (e) {
        k[e] = new N(e, 2, !1, e.toLowerCase(), null, !1, !1);
      },
    ),
    [
      "autoReverse",
      "externalResourcesRequired",
      "focusable",
      "preserveAlpha",
    ].forEach(function (e) {
      k[e] = new N(e, 2, !1, e, null, !1, !1);
    }),
    "allowFullScreen async autoFocus autoPlay controls default defer disabled disablePictureInPicture disableRemotePlayback formNoValidate hidden loop noModule noValidate open playsInline readOnly required reversed scoped seamless itemScope"
      .split(" ")
      .forEach(function (e) {
        k[e] = new N(e, 3, !1, e.toLowerCase(), null, !1, !1);
      }),
    ["checked", "multiple", "muted", "selected"].forEach(function (e) {
      k[e] = new N(e, 3, !0, e, null, !1, !1);
    }),
    ["capture", "download"].forEach(function (e) {
      k[e] = new N(e, 4, !1, e, null, !1, !1);
    }),
    ["cols", "rows", "size", "span"].forEach(function (e) {
      k[e] = new N(e, 6, !1, e, null, !1, !1);
    }),
    ["rowSpan", "start"].forEach(function (e) {
      k[e] = new N(e, 5, !1, e.toLowerCase(), null, !1, !1);
    }));
  var P = /[\-:]([a-z])/g;
  function T(e) {
    return e[1].toUpperCase();
  }
  ("accent-height alignment-baseline arabic-form baseline-shift cap-height clip-path clip-rule color-interpolation color-interpolation-filters color-profile color-rendering dominant-baseline enable-background fill-opacity fill-rule flood-color flood-opacity font-family font-size font-size-adjust font-stretch font-style font-variant font-weight glyph-name glyph-orientation-horizontal glyph-orientation-vertical horiz-adv-x horiz-origin-x image-rendering letter-spacing lighting-color marker-end marker-mid marker-start overline-position overline-thickness paint-order panose-1 pointer-events rendering-intent shape-rendering stop-color stop-opacity strikethrough-position strikethrough-thickness stroke-dasharray stroke-dashoffset stroke-linecap stroke-linejoin stroke-miterlimit stroke-opacity stroke-width text-anchor text-decoration text-rendering underline-position underline-thickness unicode-bidi unicode-range units-per-em v-alphabetic v-hanging v-ideographic v-mathematical vector-effect vert-adv-y vert-origin-x vert-origin-y word-spacing writing-mode xmlns:xlink x-height"
    .split(" ")
    .forEach(function (e) {
      var t = e.replace(P, T);
      k[t] = new N(t, 1, !1, e, null, !1, !1);
    }),
    "xlink:actuate xlink:arcrole xlink:role xlink:show xlink:title xlink:type"
      .split(" ")
      .forEach(function (e) {
        var t = e.replace(P, T);
        k[t] = new N(t, 1, !1, e, "http://www.w3.org/1999/xlink", !1, !1);
      }),
    ["xml:base", "xml:lang", "xml:space"].forEach(function (e) {
      var t = e.replace(P, T);
      k[t] = new N(t, 1, !1, e, "http://www.w3.org/XML/1998/namespace", !1, !1);
    }),
    ["tabIndex", "crossOrigin"].forEach(function (e) {
      k[e] = new N(e, 1, !1, e.toLowerCase(), null, !1, !1);
    }),
    (k.xlinkHref = new N(
      "xlinkHref",
      1,
      !1,
      "xlink:href",
      "http://www.w3.org/1999/xlink",
      !0,
      !1,
    )),
    ["src", "href", "action", "formAction"].forEach(function (e) {
      k[e] = new N(e, 1, !1, e.toLowerCase(), null, !0, !0);
    }));
  function V(e, t, n, l) {
    var o = k.hasOwnProperty(t) ? k[t] : null;
    (o !== null
      ? o.type !== 0
      : l ||
        !(2 < t.length) ||
        (t[0] !== "o" && t[0] !== "O") ||
        (t[1] !== "n" && t[1] !== "N")) &&
      (H(t, n, o, l) && (n = null),
      l || o === null
        ? b(t) &&
          (n === null ? e.removeAttribute(t) : e.setAttribute(t, "" + n))
        : o.mustUseProperty
          ? (e[o.propertyName] = n === null ? (o.type === 3 ? !1 : "") : n)
          : ((t = o.attributeName),
            (l = o.attributeNamespace),
            n === null
              ? e.removeAttribute(t)
              : ((o = o.type),
                (n = o === 3 || (o === 4 && n === !0) ? "" : "" + n),
                l ? e.setAttributeNS(l, t, n) : e.setAttribute(t, n))));
  }
  var Z = r.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED,
    ee = Symbol.for("react.element"),
    K = Symbol.for("react.portal"),
    Y = Symbol.for("react.fragment"),
    de = Symbol.for("react.strict_mode"),
    Pe = Symbol.for("react.profiler"),
    Ae = Symbol.for("react.provider"),
    st = Symbol.for("react.context"),
    Oe = Symbol.for("react.forward_ref"),
    Le = Symbol.for("react.suspense"),
    et = Symbol.for("react.suspense_list"),
    ot = Symbol.for("react.memo"),
    Be = Symbol.for("react.lazy"),
    xe = Symbol.for("react.offscreen"),
    F = Symbol.iterator;
  function q(e) {
    return e === null || typeof e != "object"
      ? null
      : ((e = (F && e[F]) || e["@@iterator"]),
        typeof e == "function" ? e : null);
  }
  var W = Object.assign,
    L;
  function I(e) {
    if (L === void 0)
      try {
        throw Error();
      } catch (n) {
        var t = n.stack.trim().match(/\n( *(at )?)/);
        L = (t && t[1]) || "";
      }
    return (
      `
` +
      L +
      e
    );
  }
  var re = !1;
  function ie(e, t) {
    if (!e || re) return "";
    re = !0;
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
          } catch (R) {
            var l = R;
          }
          Reflect.construct(e, [], t);
        } else {
          try {
            t.call();
          } catch (R) {
            l = R;
          }
          e.call(t.prototype);
        }
      else {
        try {
          throw Error();
        } catch (R) {
          l = R;
        }
        e();
      }
    } catch (R) {
      if (R && l && typeof R.stack == "string") {
        for (
          var o = R.stack.split(`
`),
            u = l.stack.split(`
`),
            f = o.length - 1,
            C = u.length - 1;
          1 <= f && 0 <= C && o[f] !== u[C];

        )
          C--;
        for (; 1 <= f && 0 <= C; f--, C--)
          if (o[f] !== u[C]) {
            if (f !== 1 || C !== 1)
              do
                if ((f--, C--, 0 > C || o[f] !== u[C])) {
                  var g =
                    `
` + o[f].replace(" at new ", " at ");
                  return (
                    e.displayName &&
                      g.includes("<anonymous>") &&
                      (g = g.replace("<anonymous>", e.displayName)),
                    g
                  );
                }
              while (1 <= f && 0 <= C);
            break;
          }
      }
    } finally {
      ((re = !1), (Error.prepareStackTrace = n));
    }
    return (e = e ? e.displayName || e.name : "") ? I(e) : "";
  }
  function ae(e) {
    switch (e.tag) {
      case 5:
        return I(e.type);
      case 16:
        return I("Lazy");
      case 13:
        return I("Suspense");
      case 19:
        return I("SuspenseList");
      case 0:
      case 2:
      case 15:
        return ((e = ie(e.type, !1)), e);
      case 11:
        return ((e = ie(e.type.render, !1)), e);
      case 1:
        return ((e = ie(e.type, !0)), e);
      default:
        return "";
    }
  }
  function ue(e) {
    if (e == null) return null;
    if (typeof e == "function") return e.displayName || e.name || null;
    if (typeof e == "string") return e;
    switch (e) {
      case Y:
        return "Fragment";
      case K:
        return "Portal";
      case Pe:
        return "Profiler";
      case de:
        return "StrictMode";
      case Le:
        return "Suspense";
      case et:
        return "SuspenseList";
    }
    if (typeof e == "object")
      switch (e.$$typeof) {
        case st:
          return (e.displayName || "Context") + ".Consumer";
        case Ae:
          return (e._context.displayName || "Context") + ".Provider";
        case Oe:
          var t = e.render;
          return (
            (e = e.displayName),
            e ||
              ((e = t.displayName || t.name || ""),
              (e = e !== "" ? "ForwardRef(" + e + ")" : "ForwardRef")),
            e
          );
        case ot:
          return (
            (t = e.displayName || null),
            t !== null ? t : ue(e.type) || "Memo"
          );
        case Be:
          ((t = e._payload), (e = e._init));
          try {
            return ue(e(t));
          } catch {}
      }
    return null;
  }
  function he(e) {
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
        return ue(t);
      case 8:
        return t === de ? "StrictMode" : "Mode";
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
  function fe(e) {
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
  function ge(e) {
    var t = e.type;
    return (
      (e = e.nodeName) &&
      e.toLowerCase() === "input" &&
      (t === "checkbox" || t === "radio")
    );
  }
  function tt(e) {
    var t = ge(e) ? "checked" : "value",
      n = Object.getOwnPropertyDescriptor(e.constructor.prototype, t),
      l = "" + e[t];
    if (
      !e.hasOwnProperty(t) &&
      typeof n < "u" &&
      typeof n.get == "function" &&
      typeof n.set == "function"
    ) {
      var o = n.get,
        u = n.set;
      return (
        Object.defineProperty(e, t, {
          configurable: !0,
          get: function () {
            return o.call(this);
          },
          set: function (f) {
            ((l = "" + f), u.call(this, f));
          },
        }),
        Object.defineProperty(e, t, { enumerable: n.enumerable }),
        {
          getValue: function () {
            return l;
          },
          setValue: function (f) {
            l = "" + f;
          },
          stopTracking: function () {
            ((e._valueTracker = null), delete e[t]);
          },
        }
      );
    }
  }
  function Xr(e) {
    e._valueTracker || (e._valueTracker = tt(e));
  }
  function X0(e) {
    if (!e) return !1;
    var t = e._valueTracker;
    if (!t) return !0;
    var n = t.getValue(),
      l = "";
    return (
      e && (l = ge(e) ? (e.checked ? "true" : "false") : e.value),
      (e = l),
      e !== n ? (t.setValue(e), !0) : !1
    );
  }
  function Jr(e) {
    if (
      ((e = e || (typeof document < "u" ? document : void 0)), typeof e > "u")
    )
      return null;
    try {
      return e.activeElement || e.body;
    } catch {
      return e.body;
    }
  }
  function El(e, t) {
    var n = t.checked;
    return W({}, t, {
      defaultChecked: void 0,
      defaultValue: void 0,
      value: void 0,
      checked: n ?? e._wrapperState.initialChecked,
    });
  }
  function J0(e, t) {
    var n = t.defaultValue == null ? "" : t.defaultValue,
      l = t.checked != null ? t.checked : t.defaultChecked;
    ((n = fe(t.value != null ? t.value : n)),
      (e._wrapperState = {
        initialChecked: l,
        initialValue: n,
        controlled:
          t.type === "checkbox" || t.type === "radio"
            ? t.checked != null
            : t.value != null,
      }));
  }
  function q0(e, t) {
    ((t = t.checked), t != null && V(e, "checked", t, !1));
  }
  function Sl(e, t) {
    q0(e, t);
    var n = fe(t.value),
      l = t.type;
    if (n != null)
      l === "number"
        ? ((n === 0 && e.value === "") || e.value != n) && (e.value = "" + n)
        : e.value !== "" + n && (e.value = "" + n);
    else if (l === "submit" || l === "reset") {
      e.removeAttribute("value");
      return;
    }
    (t.hasOwnProperty("value")
      ? kl(e, t.type, n)
      : t.hasOwnProperty("defaultValue") && kl(e, t.type, fe(t.defaultValue)),
      t.checked == null &&
        t.defaultChecked != null &&
        (e.defaultChecked = !!t.defaultChecked));
  }
  function es(e, t, n) {
    if (t.hasOwnProperty("value") || t.hasOwnProperty("defaultValue")) {
      var l = t.type;
      if (
        !(
          (l !== "submit" && l !== "reset") ||
          (t.value !== void 0 && t.value !== null)
        )
      )
        return;
      ((t = "" + e._wrapperState.initialValue),
        n || t === e.value || (e.value = t),
        (e.defaultValue = t));
    }
    ((n = e.name),
      n !== "" && (e.name = ""),
      (e.defaultChecked = !!e._wrapperState.initialChecked),
      n !== "" && (e.name = n));
  }
  function kl(e, t, n) {
    (t !== "number" || Jr(e.ownerDocument) !== e) &&
      (n == null
        ? (e.defaultValue = "" + e._wrapperState.initialValue)
        : e.defaultValue !== "" + n && (e.defaultValue = "" + n));
  }
  var ar = Array.isArray;
  function Pn(e, t, n, l) {
    if (((e = e.options), t)) {
      t = {};
      for (var o = 0; o < n.length; o++) t["$" + n[o]] = !0;
      for (n = 0; n < e.length; n++)
        ((o = t.hasOwnProperty("$" + e[n].value)),
          e[n].selected !== o && (e[n].selected = o),
          o && l && (e[n].defaultSelected = !0));
    } else {
      for (n = "" + fe(n), t = null, o = 0; o < e.length; o++) {
        if (e[o].value === n) {
          ((e[o].selected = !0), l && (e[o].defaultSelected = !0));
          return;
        }
        t !== null || e[o].disabled || (t = e[o]);
      }
      t !== null && (t.selected = !0);
    }
  }
  function Rl(e, t) {
    if (t.dangerouslySetInnerHTML != null) throw Error(a(91));
    return W({}, t, {
      value: void 0,
      defaultValue: void 0,
      children: "" + e._wrapperState.initialValue,
    });
  }
  function ts(e, t) {
    var n = t.value;
    if (n == null) {
      if (((n = t.children), (t = t.defaultValue), n != null)) {
        if (t != null) throw Error(a(92));
        if (ar(n)) {
          if (1 < n.length) throw Error(a(93));
          n = n[0];
        }
        t = n;
      }
      (t == null && (t = ""), (n = t));
    }
    e._wrapperState = { initialValue: fe(n) };
  }
  function ns(e, t) {
    var n = fe(t.value),
      l = fe(t.defaultValue);
    (n != null &&
      ((n = "" + n),
      n !== e.value && (e.value = n),
      t.defaultValue == null && e.defaultValue !== n && (e.defaultValue = n)),
      l != null && (e.defaultValue = "" + l));
  }
  function rs(e) {
    var t = e.textContent;
    t === e._wrapperState.initialValue &&
      t !== "" &&
      t !== null &&
      (e.value = t);
  }
  function ls(e) {
    switch (e) {
      case "svg":
        return "http://www.w3.org/2000/svg";
      case "math":
        return "http://www.w3.org/1998/Math/MathML";
      default:
        return "http://www.w3.org/1999/xhtml";
    }
  }
  function Ml(e, t) {
    return e == null || e === "http://www.w3.org/1999/xhtml"
      ? ls(t)
      : e === "http://www.w3.org/2000/svg" && t === "foreignObject"
        ? "http://www.w3.org/1999/xhtml"
        : e;
  }
  var qr,
    is = (function (e) {
      return typeof MSApp < "u" && MSApp.execUnsafeLocalFunction
        ? function (t, n, l, o) {
            MSApp.execUnsafeLocalFunction(function () {
              return e(t, n, l, o);
            });
          }
        : e;
    })(function (e, t) {
      if (e.namespaceURI !== "http://www.w3.org/2000/svg" || "innerHTML" in e)
        e.innerHTML = t;
      else {
        for (
          qr = qr || document.createElement("div"),
            qr.innerHTML = "<svg>" + t.valueOf().toString() + "</svg>",
            t = qr.firstChild;
          e.firstChild;

        )
          e.removeChild(e.firstChild);
        for (; t.firstChild; ) e.appendChild(t.firstChild);
      }
    });
  function ur(e, t) {
    if (t) {
      var n = e.firstChild;
      if (n && n === e.lastChild && n.nodeType === 3) {
        n.nodeValue = t;
        return;
      }
    }
    e.textContent = t;
  }
  var cr = {
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
    M5 = ["Webkit", "ms", "Moz", "O"];
  Object.keys(cr).forEach(function (e) {
    M5.forEach(function (t) {
      ((t = t + e.charAt(0).toUpperCase() + e.substring(1)), (cr[t] = cr[e]));
    });
  });
  function ss(e, t, n) {
    return t == null || typeof t == "boolean" || t === ""
      ? ""
      : n || typeof t != "number" || t === 0 || (cr.hasOwnProperty(e) && cr[e])
        ? ("" + t).trim()
        : t + "px";
  }
  function os(e, t) {
    e = e.style;
    for (var n in t)
      if (t.hasOwnProperty(n)) {
        var l = n.indexOf("--") === 0,
          o = ss(n, t[n], l);
        (n === "float" && (n = "cssFloat"),
          l ? e.setProperty(n, o) : (e[n] = o));
      }
  }
  var b5 = W(
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
    },
  );
  function bl(e, t) {
    if (t) {
      if (b5[e] && (t.children != null || t.dangerouslySetInnerHTML != null))
        throw Error(a(137, e));
      if (t.dangerouslySetInnerHTML != null) {
        if (t.children != null) throw Error(a(60));
        if (
          typeof t.dangerouslySetInnerHTML != "object" ||
          !("__html" in t.dangerouslySetInnerHTML)
        )
          throw Error(a(61));
      }
      if (t.style != null && typeof t.style != "object") throw Error(a(62));
    }
  }
  function Pl(e, t) {
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
  var Ol = null;
  function _l(e) {
    return (
      (e = e.target || e.srcElement || window),
      e.correspondingUseElement && (e = e.correspondingUseElement),
      e.nodeType === 3 ? e.parentNode : e
    );
  }
  var Fl = null,
    On = null,
    _n = null;
  function as(e) {
    if ((e = Or(e))) {
      if (typeof Fl != "function") throw Error(a(280));
      var t = e.stateNode;
      t && ((t = j1(t)), Fl(e.stateNode, e.type, t));
    }
  }
  function us(e) {
    On ? (_n ? _n.push(e) : (_n = [e])) : (On = e);
  }
  function cs() {
    if (On) {
      var e = On,
        t = _n;
      if (((_n = On = null), as(e), t)) for (e = 0; e < t.length; e++) as(t[e]);
    }
  }
  function ds(e, t) {
    return e(t);
  }
  function fs() {}
  var Il = !1;
  function ms(e, t, n) {
    if (Il) return e(t, n);
    Il = !0;
    try {
      return ds(e, t, n);
    } finally {
      ((Il = !1), (On !== null || _n !== null) && (fs(), cs()));
    }
  }
  function dr(e, t) {
    var n = e.stateNode;
    if (n === null) return null;
    var l = j1(n);
    if (l === null) return null;
    n = l[t];
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
        ((l = !l.disabled) ||
          ((e = e.type),
          (l = !(
            e === "button" ||
            e === "input" ||
            e === "select" ||
            e === "textarea"
          ))),
          (e = !l));
        break e;
      default:
        e = !1;
    }
    if (e) return null;
    if (n && typeof n != "function") throw Error(a(231, t, typeof n));
    return n;
  }
  var Dl = !1;
  if (h)
    try {
      var fr = {};
      (Object.defineProperty(fr, "passive", {
        get: function () {
          Dl = !0;
        },
      }),
        window.addEventListener("test", fr, fr),
        window.removeEventListener("test", fr, fr));
    } catch {
      Dl = !1;
    }
  function P5(e, t, n, l, o, u, f, C, g) {
    var R = Array.prototype.slice.call(arguments, 3);
    try {
      t.apply(n, R);
    } catch (D) {
      this.onError(D);
    }
  }
  var mr = !1,
    e1 = null,
    t1 = !1,
    Tl = null,
    O5 = {
      onError: function (e) {
        ((mr = !0), (e1 = e));
      },
    };
  function _5(e, t, n, l, o, u, f, C, g) {
    ((mr = !1), (e1 = null), P5.apply(O5, arguments));
  }
  function F5(e, t, n, l, o, u, f, C, g) {
    if ((_5.apply(this, arguments), mr)) {
      if (mr) {
        var R = e1;
        ((mr = !1), (e1 = null));
      } else throw Error(a(198));
      t1 || ((t1 = !0), (Tl = R));
    }
  }
  function fn(e) {
    var t = e,
      n = e;
    if (e.alternate) for (; t.return; ) t = t.return;
    else {
      e = t;
      do ((t = e), (t.flags & 4098) !== 0 && (n = t.return), (e = t.return));
      while (e);
    }
    return t.tag === 3 ? n : null;
  }
  function hs(e) {
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
  function ps(e) {
    if (fn(e) !== e) throw Error(a(188));
  }
  function I5(e) {
    var t = e.alternate;
    if (!t) {
      if (((t = fn(e)), t === null)) throw Error(a(188));
      return t !== e ? null : e;
    }
    for (var n = e, l = t; ; ) {
      var o = n.return;
      if (o === null) break;
      var u = o.alternate;
      if (u === null) {
        if (((l = o.return), l !== null)) {
          n = l;
          continue;
        }
        break;
      }
      if (o.child === u.child) {
        for (u = o.child; u; ) {
          if (u === n) return (ps(o), e);
          if (u === l) return (ps(o), t);
          u = u.sibling;
        }
        throw Error(a(188));
      }
      if (n.return !== l.return) ((n = o), (l = u));
      else {
        for (var f = !1, C = o.child; C; ) {
          if (C === n) {
            ((f = !0), (n = o), (l = u));
            break;
          }
          if (C === l) {
            ((f = !0), (l = o), (n = u));
            break;
          }
          C = C.sibling;
        }
        if (!f) {
          for (C = u.child; C; ) {
            if (C === n) {
              ((f = !0), (n = u), (l = o));
              break;
            }
            if (C === l) {
              ((f = !0), (l = u), (n = o));
              break;
            }
            C = C.sibling;
          }
          if (!f) throw Error(a(189));
        }
      }
      if (n.alternate !== l) throw Error(a(190));
    }
    if (n.tag !== 3) throw Error(a(188));
    return n.stateNode.current === n ? e : t;
  }
  function xs(e) {
    return ((e = I5(e)), e !== null ? Cs(e) : null);
  }
  function Cs(e) {
    if (e.tag === 5 || e.tag === 6) return e;
    for (e = e.child; e !== null; ) {
      var t = Cs(e);
      if (t !== null) return t;
      e = e.sibling;
    }
    return null;
  }
  var vs = s.unstable_scheduleCallback,
    gs = s.unstable_cancelCallback,
    D5 = s.unstable_shouldYield,
    T5 = s.unstable_requestPaint,
    Ee = s.unstable_now,
    A5 = s.unstable_getCurrentPriorityLevel,
    Al = s.unstable_ImmediatePriority,
    ws = s.unstable_UserBlockingPriority,
    n1 = s.unstable_NormalPriority,
    B5 = s.unstable_LowPriority,
    ys = s.unstable_IdlePriority,
    r1 = null,
    kt = null;
  function H5(e) {
    if (kt && typeof kt.onCommitFiberRoot == "function")
      try {
        kt.onCommitFiberRoot(r1, e, void 0, (e.current.flags & 128) === 128);
      } catch {}
  }
  var ht = Math.clz32 ? Math.clz32 : U5,
    V5 = Math.log,
    z5 = Math.LN2;
  function U5(e) {
    return ((e >>>= 0), e === 0 ? 32 : (31 - ((V5(e) / z5) | 0)) | 0);
  }
  var l1 = 64,
    i1 = 4194304;
  function hr(e) {
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
  function s1(e, t) {
    var n = e.pendingLanes;
    if (n === 0) return 0;
    var l = 0,
      o = e.suspendedLanes,
      u = e.pingedLanes,
      f = n & 268435455;
    if (f !== 0) {
      var C = f & ~o;
      C !== 0 ? (l = hr(C)) : ((u &= f), u !== 0 && (l = hr(u)));
    } else ((f = n & ~o), f !== 0 ? (l = hr(f)) : u !== 0 && (l = hr(u)));
    if (l === 0) return 0;
    if (
      t !== 0 &&
      t !== l &&
      (t & o) === 0 &&
      ((o = l & -l), (u = t & -t), o >= u || (o === 16 && (u & 4194240) !== 0))
    )
      return t;
    if (((l & 4) !== 0 && (l |= n & 16), (t = e.entangledLanes), t !== 0))
      for (e = e.entanglements, t &= l; 0 < t; )
        ((n = 31 - ht(t)), (o = 1 << n), (l |= e[n]), (t &= ~o));
    return l;
  }
  function Z5(e, t) {
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
  function W5(e, t) {
    for (
      var n = e.suspendedLanes,
        l = e.pingedLanes,
        o = e.expirationTimes,
        u = e.pendingLanes;
      0 < u;

    ) {
      var f = 31 - ht(u),
        C = 1 << f,
        g = o[f];
      (g === -1
        ? ((C & n) === 0 || (C & l) !== 0) && (o[f] = Z5(C, t))
        : g <= t && (e.expiredLanes |= C),
        (u &= ~C));
    }
  }
  function Bl(e) {
    return (
      (e = e.pendingLanes & -1073741825),
      e !== 0 ? e : e & 1073741824 ? 1073741824 : 0
    );
  }
  function js() {
    var e = l1;
    return ((l1 <<= 1), (l1 & 4194240) === 0 && (l1 = 64), e);
  }
  function Hl(e) {
    for (var t = [], n = 0; 31 > n; n++) t.push(e);
    return t;
  }
  function pr(e, t, n) {
    ((e.pendingLanes |= t),
      t !== 536870912 && ((e.suspendedLanes = 0), (e.pingedLanes = 0)),
      (e = e.eventTimes),
      (t = 31 - ht(t)),
      (e[t] = n));
  }
  function $5(e, t) {
    var n = e.pendingLanes & ~t;
    ((e.pendingLanes = t),
      (e.suspendedLanes = 0),
      (e.pingedLanes = 0),
      (e.expiredLanes &= t),
      (e.mutableReadLanes &= t),
      (e.entangledLanes &= t),
      (t = e.entanglements));
    var l = e.eventTimes;
    for (e = e.expirationTimes; 0 < n; ) {
      var o = 31 - ht(n),
        u = 1 << o;
      ((t[o] = 0), (l[o] = -1), (e[o] = -1), (n &= ~u));
    }
  }
  function Vl(e, t) {
    var n = (e.entangledLanes |= t);
    for (e = e.entanglements; n; ) {
      var l = 31 - ht(n),
        o = 1 << l;
      ((o & t) | (e[l] & t) && (e[l] |= t), (n &= ~o));
    }
  }
  var me = 0;
  function Ns(e) {
    return (
      (e &= -e),
      1 < e ? (4 < e ? ((e & 268435455) !== 0 ? 16 : 536870912) : 4) : 1
    );
  }
  var Ls,
    zl,
    Es,
    Ss,
    ks,
    Ul = !1,
    o1 = [],
    Ut = null,
    Zt = null,
    Wt = null,
    xr = new Map(),
    Cr = new Map(),
    $t = [],
    G5 =
      "mousedown mouseup touchcancel touchend touchstart auxclick dblclick pointercancel pointerdown pointerup dragend dragstart drop compositionend compositionstart keydown keypress keyup input textInput copy cut paste click change contextmenu reset submit".split(
        " ",
      );
  function Rs(e, t) {
    switch (e) {
      case "focusin":
      case "focusout":
        Ut = null;
        break;
      case "dragenter":
      case "dragleave":
        Zt = null;
        break;
      case "mouseover":
      case "mouseout":
        Wt = null;
        break;
      case "pointerover":
      case "pointerout":
        xr.delete(t.pointerId);
        break;
      case "gotpointercapture":
      case "lostpointercapture":
        Cr.delete(t.pointerId);
    }
  }
  function vr(e, t, n, l, o, u) {
    return e === null || e.nativeEvent !== u
      ? ((e = {
          blockedOn: t,
          domEventName: n,
          eventSystemFlags: l,
          nativeEvent: u,
          targetContainers: [o],
        }),
        t !== null && ((t = Or(t)), t !== null && zl(t)),
        e)
      : ((e.eventSystemFlags |= l),
        (t = e.targetContainers),
        o !== null && t.indexOf(o) === -1 && t.push(o),
        e);
  }
  function Q5(e, t, n, l, o) {
    switch (t) {
      case "focusin":
        return ((Ut = vr(Ut, e, t, n, l, o)), !0);
      case "dragenter":
        return ((Zt = vr(Zt, e, t, n, l, o)), !0);
      case "mouseover":
        return ((Wt = vr(Wt, e, t, n, l, o)), !0);
      case "pointerover":
        var u = o.pointerId;
        return (xr.set(u, vr(xr.get(u) || null, e, t, n, l, o)), !0);
      case "gotpointercapture":
        return (
          (u = o.pointerId),
          Cr.set(u, vr(Cr.get(u) || null, e, t, n, l, o)),
          !0
        );
    }
    return !1;
  }
  function Ms(e) {
    var t = mn(e.target);
    if (t !== null) {
      var n = fn(t);
      if (n !== null) {
        if (((t = n.tag), t === 13)) {
          if (((t = hs(n)), t !== null)) {
            ((e.blockedOn = t),
              ks(e.priority, function () {
                Es(n);
              }));
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
  function a1(e) {
    if (e.blockedOn !== null) return !1;
    for (var t = e.targetContainers; 0 < t.length; ) {
      var n = Wl(e.domEventName, e.eventSystemFlags, t[0], e.nativeEvent);
      if (n === null) {
        n = e.nativeEvent;
        var l = new n.constructor(n.type, n);
        ((Ol = l), n.target.dispatchEvent(l), (Ol = null));
      } else return ((t = Or(n)), t !== null && zl(t), (e.blockedOn = n), !1);
      t.shift();
    }
    return !0;
  }
  function bs(e, t, n) {
    a1(e) && n.delete(t);
  }
  function K5() {
    ((Ul = !1),
      Ut !== null && a1(Ut) && (Ut = null),
      Zt !== null && a1(Zt) && (Zt = null),
      Wt !== null && a1(Wt) && (Wt = null),
      xr.forEach(bs),
      Cr.forEach(bs));
  }
  function gr(e, t) {
    e.blockedOn === t &&
      ((e.blockedOn = null),
      Ul ||
        ((Ul = !0),
        s.unstable_scheduleCallback(s.unstable_NormalPriority, K5)));
  }
  function wr(e) {
    function t(o) {
      return gr(o, e);
    }
    if (0 < o1.length) {
      gr(o1[0], e);
      for (var n = 1; n < o1.length; n++) {
        var l = o1[n];
        l.blockedOn === e && (l.blockedOn = null);
      }
    }
    for (
      Ut !== null && gr(Ut, e),
        Zt !== null && gr(Zt, e),
        Wt !== null && gr(Wt, e),
        xr.forEach(t),
        Cr.forEach(t),
        n = 0;
      n < $t.length;
      n++
    )
      ((l = $t[n]), l.blockedOn === e && (l.blockedOn = null));
    for (; 0 < $t.length && ((n = $t[0]), n.blockedOn === null); )
      (Ms(n), n.blockedOn === null && $t.shift());
  }
  var Fn = Z.ReactCurrentBatchConfig,
    u1 = !0;
  function Y5(e, t, n, l) {
    var o = me,
      u = Fn.transition;
    Fn.transition = null;
    try {
      ((me = 1), Zl(e, t, n, l));
    } finally {
      ((me = o), (Fn.transition = u));
    }
  }
  function X5(e, t, n, l) {
    var o = me,
      u = Fn.transition;
    Fn.transition = null;
    try {
      ((me = 4), Zl(e, t, n, l));
    } finally {
      ((me = o), (Fn.transition = u));
    }
  }
  function Zl(e, t, n, l) {
    if (u1) {
      var o = Wl(e, t, n, l);
      if (o === null) (ai(e, t, l, c1, n), Rs(e, l));
      else if (Q5(o, e, t, n, l)) l.stopPropagation();
      else if ((Rs(e, l), t & 4 && -1 < G5.indexOf(e))) {
        for (; o !== null; ) {
          var u = Or(o);
          if (
            (u !== null && Ls(u),
            (u = Wl(e, t, n, l)),
            u === null && ai(e, t, l, c1, n),
            u === o)
          )
            break;
          o = u;
        }
        o !== null && l.stopPropagation();
      } else ai(e, t, l, null, n);
    }
  }
  var c1 = null;
  function Wl(e, t, n, l) {
    if (((c1 = null), (e = _l(l)), (e = mn(e)), e !== null))
      if (((t = fn(e)), t === null)) e = null;
      else if (((n = t.tag), n === 13)) {
        if (((e = hs(t)), e !== null)) return e;
        e = null;
      } else if (n === 3) {
        if (t.stateNode.current.memoizedState.isDehydrated)
          return t.tag === 3 ? t.stateNode.containerInfo : null;
        e = null;
      } else t !== e && (e = null);
    return ((c1 = e), null);
  }
  function Ps(e) {
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
        switch (A5()) {
          case Al:
            return 1;
          case ws:
            return 4;
          case n1:
          case B5:
            return 16;
          case ys:
            return 536870912;
          default:
            return 16;
        }
      default:
        return 16;
    }
  }
  var Gt = null,
    $l = null,
    d1 = null;
  function Os() {
    if (d1) return d1;
    var e,
      t = $l,
      n = t.length,
      l,
      o = "value" in Gt ? Gt.value : Gt.textContent,
      u = o.length;
    for (e = 0; e < n && t[e] === o[e]; e++);
    var f = n - e;
    for (l = 1; l <= f && t[n - l] === o[u - l]; l++);
    return (d1 = o.slice(e, 1 < l ? 1 - l : void 0));
  }
  function f1(e) {
    var t = e.keyCode;
    return (
      "charCode" in e
        ? ((e = e.charCode), e === 0 && t === 13 && (e = 13))
        : (e = t),
      e === 10 && (e = 13),
      32 <= e || e === 13 ? e : 0
    );
  }
  function m1() {
    return !0;
  }
  function _s() {
    return !1;
  }
  function nt(e) {
    function t(n, l, o, u, f) {
      ((this._reactName = n),
        (this._targetInst = o),
        (this.type = l),
        (this.nativeEvent = u),
        (this.target = f),
        (this.currentTarget = null));
      for (var C in e)
        e.hasOwnProperty(C) && ((n = e[C]), (this[C] = n ? n(u) : u[C]));
      return (
        (this.isDefaultPrevented = (
          u.defaultPrevented != null ? u.defaultPrevented : u.returnValue === !1
        )
          ? m1
          : _s),
        (this.isPropagationStopped = _s),
        this
      );
    }
    return (
      W(t.prototype, {
        preventDefault: function () {
          this.defaultPrevented = !0;
          var n = this.nativeEvent;
          n &&
            (n.preventDefault
              ? n.preventDefault()
              : typeof n.returnValue != "unknown" && (n.returnValue = !1),
            (this.isDefaultPrevented = m1));
        },
        stopPropagation: function () {
          var n = this.nativeEvent;
          n &&
            (n.stopPropagation
              ? n.stopPropagation()
              : typeof n.cancelBubble != "unknown" && (n.cancelBubble = !0),
            (this.isPropagationStopped = m1));
        },
        persist: function () {},
        isPersistent: m1,
      }),
      t
    );
  }
  var In = {
      eventPhase: 0,
      bubbles: 0,
      cancelable: 0,
      timeStamp: function (e) {
        return e.timeStamp || Date.now();
      },
      defaultPrevented: 0,
      isTrusted: 0,
    },
    Gl = nt(In),
    yr = W({}, In, { view: 0, detail: 0 }),
    J5 = nt(yr),
    Ql,
    Kl,
    jr,
    h1 = W({}, yr, {
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
      getModifierState: Xl,
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
          : (e !== jr &&
              (jr && e.type === "mousemove"
                ? ((Ql = e.screenX - jr.screenX), (Kl = e.screenY - jr.screenY))
                : (Kl = Ql = 0),
              (jr = e)),
            Ql);
      },
      movementY: function (e) {
        return "movementY" in e ? e.movementY : Kl;
      },
    }),
    Fs = nt(h1),
    q5 = W({}, h1, { dataTransfer: 0 }),
    e3 = nt(q5),
    t3 = W({}, yr, { relatedTarget: 0 }),
    Yl = nt(t3),
    n3 = W({}, In, { animationName: 0, elapsedTime: 0, pseudoElement: 0 }),
    r3 = nt(n3),
    l3 = W({}, In, {
      clipboardData: function (e) {
        return "clipboardData" in e ? e.clipboardData : window.clipboardData;
      },
    }),
    i3 = nt(l3),
    s3 = W({}, In, { data: 0 }),
    Is = nt(s3),
    o3 = {
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
    a3 = {
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
    u3 = {
      Alt: "altKey",
      Control: "ctrlKey",
      Meta: "metaKey",
      Shift: "shiftKey",
    };
  function c3(e) {
    var t = this.nativeEvent;
    return t.getModifierState
      ? t.getModifierState(e)
      : (e = u3[e])
        ? !!t[e]
        : !1;
  }
  function Xl() {
    return c3;
  }
  var d3 = W({}, yr, {
      key: function (e) {
        if (e.key) {
          var t = o3[e.key] || e.key;
          if (t !== "Unidentified") return t;
        }
        return e.type === "keypress"
          ? ((e = f1(e)), e === 13 ? "Enter" : String.fromCharCode(e))
          : e.type === "keydown" || e.type === "keyup"
            ? a3[e.keyCode] || "Unidentified"
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
      getModifierState: Xl,
      charCode: function (e) {
        return e.type === "keypress" ? f1(e) : 0;
      },
      keyCode: function (e) {
        return e.type === "keydown" || e.type === "keyup" ? e.keyCode : 0;
      },
      which: function (e) {
        return e.type === "keypress"
          ? f1(e)
          : e.type === "keydown" || e.type === "keyup"
            ? e.keyCode
            : 0;
      },
    }),
    f3 = nt(d3),
    m3 = W({}, h1, {
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
    Ds = nt(m3),
    h3 = W({}, yr, {
      touches: 0,
      targetTouches: 0,
      changedTouches: 0,
      altKey: 0,
      metaKey: 0,
      ctrlKey: 0,
      shiftKey: 0,
      getModifierState: Xl,
    }),
    p3 = nt(h3),
    x3 = W({}, In, { propertyName: 0, elapsedTime: 0, pseudoElement: 0 }),
    C3 = nt(x3),
    v3 = W({}, h1, {
      deltaX: function (e) {
        return "deltaX" in e
          ? e.deltaX
          : "wheelDeltaX" in e
            ? -e.wheelDeltaX
            : 0;
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
    g3 = nt(v3),
    w3 = [9, 13, 27, 32],
    Jl = h && "CompositionEvent" in window,
    Nr = null;
  h && "documentMode" in document && (Nr = document.documentMode);
  var y3 = h && "TextEvent" in window && !Nr,
    Ts = h && (!Jl || (Nr && 8 < Nr && 11 >= Nr)),
    As = " ",
    Bs = !1;
  function Hs(e, t) {
    switch (e) {
      case "keyup":
        return w3.indexOf(t.keyCode) !== -1;
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
  function Vs(e) {
    return (
      (e = e.detail),
      typeof e == "object" && "data" in e ? e.data : null
    );
  }
  var Dn = !1;
  function j3(e, t) {
    switch (e) {
      case "compositionend":
        return Vs(t);
      case "keypress":
        return t.which !== 32 ? null : ((Bs = !0), As);
      case "textInput":
        return ((e = t.data), e === As && Bs ? null : e);
      default:
        return null;
    }
  }
  function N3(e, t) {
    if (Dn)
      return e === "compositionend" || (!Jl && Hs(e, t))
        ? ((e = Os()), (d1 = $l = Gt = null), (Dn = !1), e)
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
        return Ts && t.locale !== "ko" ? null : t.data;
      default:
        return null;
    }
  }
  var L3 = {
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
  function zs(e) {
    var t = e && e.nodeName && e.nodeName.toLowerCase();
    return t === "input" ? !!L3[e.type] : t === "textarea";
  }
  function Us(e, t, n, l) {
    (us(l),
      (t = g1(t, "onChange")),
      0 < t.length &&
        ((n = new Gl("onChange", "change", null, n, l)),
        e.push({ event: n, listeners: t })));
  }
  var Lr = null,
    Er = null;
  function E3(e) {
    oo(e, 0);
  }
  function p1(e) {
    var t = Vn(e);
    if (X0(t)) return e;
  }
  function S3(e, t) {
    if (e === "change") return t;
  }
  var Zs = !1;
  if (h) {
    var ql;
    if (h) {
      var ei = "oninput" in document;
      if (!ei) {
        var Ws = document.createElement("div");
        (Ws.setAttribute("oninput", "return;"),
          (ei = typeof Ws.oninput == "function"));
      }
      ql = ei;
    } else ql = !1;
    Zs = ql && (!document.documentMode || 9 < document.documentMode);
  }
  function $s() {
    Lr && (Lr.detachEvent("onpropertychange", Gs), (Er = Lr = null));
  }
  function Gs(e) {
    if (e.propertyName === "value" && p1(Er)) {
      var t = [];
      (Us(t, Er, e, _l(e)), ms(E3, t));
    }
  }
  function k3(e, t, n) {
    e === "focusin"
      ? ($s(), (Lr = t), (Er = n), Lr.attachEvent("onpropertychange", Gs))
      : e === "focusout" && $s();
  }
  function R3(e) {
    if (e === "selectionchange" || e === "keyup" || e === "keydown")
      return p1(Er);
  }
  function M3(e, t) {
    if (e === "click") return p1(t);
  }
  function b3(e, t) {
    if (e === "input" || e === "change") return p1(t);
  }
  function P3(e, t) {
    return (e === t && (e !== 0 || 1 / e === 1 / t)) || (e !== e && t !== t);
  }
  var pt = typeof Object.is == "function" ? Object.is : P3;
  function Sr(e, t) {
    if (pt(e, t)) return !0;
    if (
      typeof e != "object" ||
      e === null ||
      typeof t != "object" ||
      t === null
    )
      return !1;
    var n = Object.keys(e),
      l = Object.keys(t);
    if (n.length !== l.length) return !1;
    for (l = 0; l < n.length; l++) {
      var o = n[l];
      if (!v.call(t, o) || !pt(e[o], t[o])) return !1;
    }
    return !0;
  }
  function Qs(e) {
    for (; e && e.firstChild; ) e = e.firstChild;
    return e;
  }
  function Ks(e, t) {
    var n = Qs(e);
    e = 0;
    for (var l; n; ) {
      if (n.nodeType === 3) {
        if (((l = e + n.textContent.length), e <= t && l >= t))
          return { node: n, offset: t - e };
        e = l;
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
      n = Qs(n);
    }
  }
  function Ys(e, t) {
    return e && t
      ? e === t
        ? !0
        : e && e.nodeType === 3
          ? !1
          : t && t.nodeType === 3
            ? Ys(e, t.parentNode)
            : "contains" in e
              ? e.contains(t)
              : e.compareDocumentPosition
                ? !!(e.compareDocumentPosition(t) & 16)
                : !1
      : !1;
  }
  function Xs() {
    for (var e = window, t = Jr(); t instanceof e.HTMLIFrameElement; ) {
      try {
        var n = typeof t.contentWindow.location.href == "string";
      } catch {
        n = !1;
      }
      if (n) e = t.contentWindow;
      else break;
      t = Jr(e.document);
    }
    return t;
  }
  function ti(e) {
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
  function O3(e) {
    var t = Xs(),
      n = e.focusedElem,
      l = e.selectionRange;
    if (
      t !== n &&
      n &&
      n.ownerDocument &&
      Ys(n.ownerDocument.documentElement, n)
    ) {
      if (l !== null && ti(n)) {
        if (
          ((t = l.start),
          (e = l.end),
          e === void 0 && (e = t),
          "selectionStart" in n)
        )
          ((n.selectionStart = t),
            (n.selectionEnd = Math.min(e, n.value.length)));
        else if (
          ((e = ((t = n.ownerDocument || document) && t.defaultView) || window),
          e.getSelection)
        ) {
          e = e.getSelection();
          var o = n.textContent.length,
            u = Math.min(l.start, o);
          ((l = l.end === void 0 ? u : Math.min(l.end, o)),
            !e.extend && u > l && ((o = l), (l = u), (u = o)),
            (o = Ks(n, u)));
          var f = Ks(n, l);
          o &&
            f &&
            (e.rangeCount !== 1 ||
              e.anchorNode !== o.node ||
              e.anchorOffset !== o.offset ||
              e.focusNode !== f.node ||
              e.focusOffset !== f.offset) &&
            ((t = t.createRange()),
            t.setStart(o.node, o.offset),
            e.removeAllRanges(),
            u > l
              ? (e.addRange(t), e.extend(f.node, f.offset))
              : (t.setEnd(f.node, f.offset), e.addRange(t)));
        }
      }
      for (t = [], e = n; (e = e.parentNode); )
        e.nodeType === 1 &&
          t.push({ element: e, left: e.scrollLeft, top: e.scrollTop });
      for (typeof n.focus == "function" && n.focus(), n = 0; n < t.length; n++)
        ((e = t[n]),
          (e.element.scrollLeft = e.left),
          (e.element.scrollTop = e.top));
    }
  }
  var _3 = h && "documentMode" in document && 11 >= document.documentMode,
    Tn = null,
    ni = null,
    kr = null,
    ri = !1;
  function Js(e, t, n) {
    var l =
      n.window === n ? n.document : n.nodeType === 9 ? n : n.ownerDocument;
    ri ||
      Tn == null ||
      Tn !== Jr(l) ||
      ((l = Tn),
      "selectionStart" in l && ti(l)
        ? (l = { start: l.selectionStart, end: l.selectionEnd })
        : ((l = (
            (l.ownerDocument && l.ownerDocument.defaultView) ||
            window
          ).getSelection()),
          (l = {
            anchorNode: l.anchorNode,
            anchorOffset: l.anchorOffset,
            focusNode: l.focusNode,
            focusOffset: l.focusOffset,
          })),
      (kr && Sr(kr, l)) ||
        ((kr = l),
        (l = g1(ni, "onSelect")),
        0 < l.length &&
          ((t = new Gl("onSelect", "select", null, t, n)),
          e.push({ event: t, listeners: l }),
          (t.target = Tn))));
  }
  function x1(e, t) {
    var n = {};
    return (
      (n[e.toLowerCase()] = t.toLowerCase()),
      (n["Webkit" + e] = "webkit" + t),
      (n["Moz" + e] = "moz" + t),
      n
    );
  }
  var An = {
      animationend: x1("Animation", "AnimationEnd"),
      animationiteration: x1("Animation", "AnimationIteration"),
      animationstart: x1("Animation", "AnimationStart"),
      transitionend: x1("Transition", "TransitionEnd"),
    },
    li = {},
    qs = {};
  h &&
    ((qs = document.createElement("div").style),
    "AnimationEvent" in window ||
      (delete An.animationend.animation,
      delete An.animationiteration.animation,
      delete An.animationstart.animation),
    "TransitionEvent" in window || delete An.transitionend.transition);
  function C1(e) {
    if (li[e]) return li[e];
    if (!An[e]) return e;
    var t = An[e],
      n;
    for (n in t) if (t.hasOwnProperty(n) && n in qs) return (li[e] = t[n]);
    return e;
  }
  var eo = C1("animationend"),
    to = C1("animationiteration"),
    no = C1("animationstart"),
    ro = C1("transitionend"),
    lo = new Map(),
    io =
      "abort auxClick cancel canPlay canPlayThrough click close contextMenu copy cut drag dragEnd dragEnter dragExit dragLeave dragOver dragStart drop durationChange emptied encrypted ended error gotPointerCapture input invalid keyDown keyPress keyUp load loadedData loadedMetadata loadStart lostPointerCapture mouseDown mouseMove mouseOut mouseOver mouseUp paste pause play playing pointerCancel pointerDown pointerMove pointerOut pointerOver pointerUp progress rateChange reset resize seeked seeking stalled submit suspend timeUpdate touchCancel touchEnd touchStart volumeChange scroll toggle touchMove waiting wheel".split(
        " ",
      );
  function Qt(e, t) {
    (lo.set(e, t), m(t, [e]));
  }
  for (var ii = 0; ii < io.length; ii++) {
    var si = io[ii],
      F3 = si.toLowerCase(),
      I3 = si[0].toUpperCase() + si.slice(1);
    Qt(F3, "on" + I3);
  }
  (Qt(eo, "onAnimationEnd"),
    Qt(to, "onAnimationIteration"),
    Qt(no, "onAnimationStart"),
    Qt("dblclick", "onDoubleClick"),
    Qt("focusin", "onFocus"),
    Qt("focusout", "onBlur"),
    Qt(ro, "onTransitionEnd"),
    x("onMouseEnter", ["mouseout", "mouseover"]),
    x("onMouseLeave", ["mouseout", "mouseover"]),
    x("onPointerEnter", ["pointerout", "pointerover"]),
    x("onPointerLeave", ["pointerout", "pointerover"]),
    m(
      "onChange",
      "change click focusin focusout input keydown keyup selectionchange".split(
        " ",
      ),
    ),
    m(
      "onSelect",
      "focusout contextmenu dragend focusin keydown keyup mousedown mouseup selectionchange".split(
        " ",
      ),
    ),
    m("onBeforeInput", ["compositionend", "keypress", "textInput", "paste"]),
    m(
      "onCompositionEnd",
      "compositionend focusout keydown keypress keyup mousedown".split(" "),
    ),
    m(
      "onCompositionStart",
      "compositionstart focusout keydown keypress keyup mousedown".split(" "),
    ),
    m(
      "onCompositionUpdate",
      "compositionupdate focusout keydown keypress keyup mousedown".split(" "),
    ));
  var Rr =
      "abort canplay canplaythrough durationchange emptied encrypted ended error loadeddata loadedmetadata loadstart pause play playing progress ratechange resize seeked seeking stalled suspend timeupdate volumechange waiting".split(
        " ",
      ),
    D3 = new Set(
      "cancel close invalid load scroll toggle".split(" ").concat(Rr),
    );
  function so(e, t, n) {
    var l = e.type || "unknown-event";
    ((e.currentTarget = n), F5(l, t, void 0, e), (e.currentTarget = null));
  }
  function oo(e, t) {
    t = (t & 4) !== 0;
    for (var n = 0; n < e.length; n++) {
      var l = e[n],
        o = l.event;
      l = l.listeners;
      e: {
        var u = void 0;
        if (t)
          for (var f = l.length - 1; 0 <= f; f--) {
            var C = l[f],
              g = C.instance,
              R = C.currentTarget;
            if (((C = C.listener), g !== u && o.isPropagationStopped()))
              break e;
            (so(o, C, R), (u = g));
          }
        else
          for (f = 0; f < l.length; f++) {
            if (
              ((C = l[f]),
              (g = C.instance),
              (R = C.currentTarget),
              (C = C.listener),
              g !== u && o.isPropagationStopped())
            )
              break e;
            (so(o, C, R), (u = g));
          }
      }
    }
    if (t1) throw ((e = Tl), (t1 = !1), (Tl = null), e);
  }
  function Ce(e, t) {
    var n = t[hi];
    n === void 0 && (n = t[hi] = new Set());
    var l = e + "__bubble";
    n.has(l) || (ao(t, e, 2, !1), n.add(l));
  }
  function oi(e, t, n) {
    var l = 0;
    (t && (l |= 4), ao(n, e, l, t));
  }
  var v1 = "_reactListening" + Math.random().toString(36).slice(2);
  function Mr(e) {
    if (!e[v1]) {
      ((e[v1] = !0),
        c.forEach(function (n) {
          n !== "selectionchange" && (D3.has(n) || oi(n, !1, e), oi(n, !0, e));
        }));
      var t = e.nodeType === 9 ? e : e.ownerDocument;
      t === null || t[v1] || ((t[v1] = !0), oi("selectionchange", !1, t));
    }
  }
  function ao(e, t, n, l) {
    switch (Ps(t)) {
      case 1:
        var o = Y5;
        break;
      case 4:
        o = X5;
        break;
      default:
        o = Zl;
    }
    ((n = o.bind(null, t, n, e)),
      (o = void 0),
      !Dl ||
        (t !== "touchstart" && t !== "touchmove" && t !== "wheel") ||
        (o = !0),
      l
        ? o !== void 0
          ? e.addEventListener(t, n, { capture: !0, passive: o })
          : e.addEventListener(t, n, !0)
        : o !== void 0
          ? e.addEventListener(t, n, { passive: o })
          : e.addEventListener(t, n, !1));
  }
  function ai(e, t, n, l, o) {
    var u = l;
    if ((t & 1) === 0 && (t & 2) === 0 && l !== null)
      e: for (;;) {
        if (l === null) return;
        var f = l.tag;
        if (f === 3 || f === 4) {
          var C = l.stateNode.containerInfo;
          if (C === o || (C.nodeType === 8 && C.parentNode === o)) break;
          if (f === 4)
            for (f = l.return; f !== null; ) {
              var g = f.tag;
              if (
                (g === 3 || g === 4) &&
                ((g = f.stateNode.containerInfo),
                g === o || (g.nodeType === 8 && g.parentNode === o))
              )
                return;
              f = f.return;
            }
          for (; C !== null; ) {
            if (((f = mn(C)), f === null)) return;
            if (((g = f.tag), g === 5 || g === 6)) {
              l = u = f;
              continue e;
            }
            C = C.parentNode;
          }
        }
        l = l.return;
      }
    ms(function () {
      var R = u,
        D = _l(n),
        A = [];
      e: {
        var _ = lo.get(e);
        if (_ !== void 0) {
          var z = Gl,
            $ = e;
          switch (e) {
            case "keypress":
              if (f1(n) === 0) break e;
            case "keydown":
            case "keyup":
              z = f3;
              break;
            case "focusin":
              (($ = "focus"), (z = Yl));
              break;
            case "focusout":
              (($ = "blur"), (z = Yl));
              break;
            case "beforeblur":
            case "afterblur":
              z = Yl;
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
              z = Fs;
              break;
            case "drag":
            case "dragend":
            case "dragenter":
            case "dragexit":
            case "dragleave":
            case "dragover":
            case "dragstart":
            case "drop":
              z = e3;
              break;
            case "touchcancel":
            case "touchend":
            case "touchmove":
            case "touchstart":
              z = p3;
              break;
            case eo:
            case to:
            case no:
              z = r3;
              break;
            case ro:
              z = C3;
              break;
            case "scroll":
              z = J5;
              break;
            case "wheel":
              z = g3;
              break;
            case "copy":
            case "cut":
            case "paste":
              z = i3;
              break;
            case "gotpointercapture":
            case "lostpointercapture":
            case "pointercancel":
            case "pointerdown":
            case "pointermove":
            case "pointerout":
            case "pointerover":
            case "pointerup":
              z = Ds;
          }
          var G = (t & 4) !== 0,
            Se = !G && e === "scroll",
            E = G ? (_ !== null ? _ + "Capture" : null) : _;
          G = [];
          for (var w = R, S; w !== null; ) {
            S = w;
            var B = S.stateNode;
            if (
              (S.tag === 5 &&
                B !== null &&
                ((S = B),
                E !== null &&
                  ((B = dr(w, E)), B != null && G.push(br(w, B, S)))),
              Se)
            )
              break;
            w = w.return;
          }
          0 < G.length &&
            ((_ = new z(_, $, null, n, D)), A.push({ event: _, listeners: G }));
        }
      }
      if ((t & 7) === 0) {
        e: {
          if (
            ((_ = e === "mouseover" || e === "pointerover"),
            (z = e === "mouseout" || e === "pointerout"),
            _ &&
              n !== Ol &&
              ($ = n.relatedTarget || n.fromElement) &&
              (mn($) || $[_t]))
          )
            break e;
          if (
            (z || _) &&
            ((_ =
              D.window === D
                ? D
                : (_ = D.ownerDocument)
                  ? _.defaultView || _.parentWindow
                  : window),
            z
              ? (($ = n.relatedTarget || n.toElement),
                (z = R),
                ($ = $ ? mn($) : null),
                $ !== null &&
                  ((Se = fn($)), $ !== Se || ($.tag !== 5 && $.tag !== 6)) &&
                  ($ = null))
              : ((z = null), ($ = R)),
            z !== $)
          ) {
            if (
              ((G = Fs),
              (B = "onMouseLeave"),
              (E = "onMouseEnter"),
              (w = "mouse"),
              (e === "pointerout" || e === "pointerover") &&
                ((G = Ds),
                (B = "onPointerLeave"),
                (E = "onPointerEnter"),
                (w = "pointer")),
              (Se = z == null ? _ : Vn(z)),
              (S = $ == null ? _ : Vn($)),
              (_ = new G(B, w + "leave", z, n, D)),
              (_.target = Se),
              (_.relatedTarget = S),
              (B = null),
              mn(D) === R &&
                ((G = new G(E, w + "enter", $, n, D)),
                (G.target = S),
                (G.relatedTarget = Se),
                (B = G)),
              (Se = B),
              z && $)
            )
              t: {
                for (G = z, E = $, w = 0, S = G; S; S = Bn(S)) w++;
                for (S = 0, B = E; B; B = Bn(B)) S++;
                for (; 0 < w - S; ) ((G = Bn(G)), w--);
                for (; 0 < S - w; ) ((E = Bn(E)), S--);
                for (; w--; ) {
                  if (G === E || (E !== null && G === E.alternate)) break t;
                  ((G = Bn(G)), (E = Bn(E)));
                }
                G = null;
              }
            else G = null;
            (z !== null && uo(A, _, z, G, !1),
              $ !== null && Se !== null && uo(A, Se, $, G, !0));
          }
        }
        e: {
          if (
            ((_ = R ? Vn(R) : window),
            (z = _.nodeName && _.nodeName.toLowerCase()),
            z === "select" || (z === "input" && _.type === "file"))
          )
            var Q = S3;
          else if (zs(_))
            if (Zs) Q = b3;
            else {
              Q = R3;
              var X = k3;
            }
          else
            (z = _.nodeName) &&
              z.toLowerCase() === "input" &&
              (_.type === "checkbox" || _.type === "radio") &&
              (Q = M3);
          if (Q && (Q = Q(e, R))) {
            Us(A, Q, n, D);
            break e;
          }
          (X && X(e, _, R),
            e === "focusout" &&
              (X = _._wrapperState) &&
              X.controlled &&
              _.type === "number" &&
              kl(_, "number", _.value));
        }
        switch (((X = R ? Vn(R) : window), e)) {
          case "focusin":
            (zs(X) || X.contentEditable === "true") &&
              ((Tn = X), (ni = R), (kr = null));
            break;
          case "focusout":
            kr = ni = Tn = null;
            break;
          case "mousedown":
            ri = !0;
            break;
          case "contextmenu":
          case "mouseup":
          case "dragend":
            ((ri = !1), Js(A, n, D));
            break;
          case "selectionchange":
            if (_3) break;
          case "keydown":
          case "keyup":
            Js(A, n, D);
        }
        var J;
        if (Jl)
          e: {
            switch (e) {
              case "compositionstart":
                var te = "onCompositionStart";
                break e;
              case "compositionend":
                te = "onCompositionEnd";
                break e;
              case "compositionupdate":
                te = "onCompositionUpdate";
                break e;
            }
            te = void 0;
          }
        else
          Dn
            ? Hs(e, n) && (te = "onCompositionEnd")
            : e === "keydown" &&
              n.keyCode === 229 &&
              (te = "onCompositionStart");
        (te &&
          (Ts &&
            n.locale !== "ko" &&
            (Dn || te !== "onCompositionStart"
              ? te === "onCompositionEnd" && Dn && (J = Os())
              : ((Gt = D),
                ($l = "value" in Gt ? Gt.value : Gt.textContent),
                (Dn = !0))),
          (X = g1(R, te)),
          0 < X.length &&
            ((te = new Is(te, e, null, n, D)),
            A.push({ event: te, listeners: X }),
            J ? (te.data = J) : ((J = Vs(n)), J !== null && (te.data = J)))),
          (J = y3 ? j3(e, n) : N3(e, n)) &&
            ((R = g1(R, "onBeforeInput")),
            0 < R.length &&
              ((D = new Is("onBeforeInput", "beforeinput", null, n, D)),
              A.push({ event: D, listeners: R }),
              (D.data = J))));
      }
      oo(A, t);
    });
  }
  function br(e, t, n) {
    return { instance: e, listener: t, currentTarget: n };
  }
  function g1(e, t) {
    for (var n = t + "Capture", l = []; e !== null; ) {
      var o = e,
        u = o.stateNode;
      (o.tag === 5 &&
        u !== null &&
        ((o = u),
        (u = dr(e, n)),
        u != null && l.unshift(br(e, u, o)),
        (u = dr(e, t)),
        u != null && l.push(br(e, u, o))),
        (e = e.return));
    }
    return l;
  }
  function Bn(e) {
    if (e === null) return null;
    do e = e.return;
    while (e && e.tag !== 5);
    return e || null;
  }
  function uo(e, t, n, l, o) {
    for (var u = t._reactName, f = []; n !== null && n !== l; ) {
      var C = n,
        g = C.alternate,
        R = C.stateNode;
      if (g !== null && g === l) break;
      (C.tag === 5 &&
        R !== null &&
        ((C = R),
        o
          ? ((g = dr(n, u)), g != null && f.unshift(br(n, g, C)))
          : o || ((g = dr(n, u)), g != null && f.push(br(n, g, C)))),
        (n = n.return));
    }
    f.length !== 0 && e.push({ event: t, listeners: f });
  }
  var T3 = /\r\n?/g,
    A3 = /\u0000|\uFFFD/g;
  function co(e) {
    return (typeof e == "string" ? e : "" + e)
      .replace(
        T3,
        `
`,
      )
      .replace(A3, "");
  }
  function w1(e, t, n) {
    if (((t = co(t)), co(e) !== t && n)) throw Error(a(425));
  }
  function y1() {}
  var ui = null,
    ci = null;
  function di(e, t) {
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
  var fi = typeof setTimeout == "function" ? setTimeout : void 0,
    B3 = typeof clearTimeout == "function" ? clearTimeout : void 0,
    fo = typeof Promise == "function" ? Promise : void 0,
    H3 =
      typeof queueMicrotask == "function"
        ? queueMicrotask
        : typeof fo < "u"
          ? function (e) {
              return fo.resolve(null).then(e).catch(V3);
            }
          : fi;
  function V3(e) {
    setTimeout(function () {
      throw e;
    });
  }
  function mi(e, t) {
    var n = t,
      l = 0;
    do {
      var o = n.nextSibling;
      if ((e.removeChild(n), o && o.nodeType === 8))
        if (((n = o.data), n === "/$")) {
          if (l === 0) {
            (e.removeChild(o), wr(t));
            return;
          }
          l--;
        } else (n !== "$" && n !== "$?" && n !== "$!") || l++;
      n = o;
    } while (n);
    wr(t);
  }
  function Kt(e) {
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
  function mo(e) {
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
  var Hn = Math.random().toString(36).slice(2),
    Rt = "__reactFiber$" + Hn,
    Pr = "__reactProps$" + Hn,
    _t = "__reactContainer$" + Hn,
    hi = "__reactEvents$" + Hn,
    z3 = "__reactListeners$" + Hn,
    U3 = "__reactHandles$" + Hn;
  function mn(e) {
    var t = e[Rt];
    if (t) return t;
    for (var n = e.parentNode; n; ) {
      if ((t = n[_t] || n[Rt])) {
        if (
          ((n = t.alternate),
          t.child !== null || (n !== null && n.child !== null))
        )
          for (e = mo(e); e !== null; ) {
            if ((n = e[Rt])) return n;
            e = mo(e);
          }
        return t;
      }
      ((e = n), (n = e.parentNode));
    }
    return null;
  }
  function Or(e) {
    return (
      (e = e[Rt] || e[_t]),
      !e || (e.tag !== 5 && e.tag !== 6 && e.tag !== 13 && e.tag !== 3)
        ? null
        : e
    );
  }
  function Vn(e) {
    if (e.tag === 5 || e.tag === 6) return e.stateNode;
    throw Error(a(33));
  }
  function j1(e) {
    return e[Pr] || null;
  }
  var pi = [],
    zn = -1;
  function Yt(e) {
    return { current: e };
  }
  function ve(e) {
    0 > zn || ((e.current = pi[zn]), (pi[zn] = null), zn--);
  }
  function pe(e, t) {
    (zn++, (pi[zn] = e.current), (e.current = t));
  }
  var Xt = {},
    He = Yt(Xt),
    Ge = Yt(!1),
    hn = Xt;
  function Un(e, t) {
    var n = e.type.contextTypes;
    if (!n) return Xt;
    var l = e.stateNode;
    if (l && l.__reactInternalMemoizedUnmaskedChildContext === t)
      return l.__reactInternalMemoizedMaskedChildContext;
    var o = {},
      u;
    for (u in n) o[u] = t[u];
    return (
      l &&
        ((e = e.stateNode),
        (e.__reactInternalMemoizedUnmaskedChildContext = t),
        (e.__reactInternalMemoizedMaskedChildContext = o)),
      o
    );
  }
  function Qe(e) {
    return ((e = e.childContextTypes), e != null);
  }
  function N1() {
    (ve(Ge), ve(He));
  }
  function ho(e, t, n) {
    if (He.current !== Xt) throw Error(a(168));
    (pe(He, t), pe(Ge, n));
  }
  function po(e, t, n) {
    var l = e.stateNode;
    if (((t = t.childContextTypes), typeof l.getChildContext != "function"))
      return n;
    l = l.getChildContext();
    for (var o in l) if (!(o in t)) throw Error(a(108, he(e) || "Unknown", o));
    return W({}, n, l);
  }
  function L1(e) {
    return (
      (e =
        ((e = e.stateNode) && e.__reactInternalMemoizedMergedChildContext) ||
        Xt),
      (hn = He.current),
      pe(He, e),
      pe(Ge, Ge.current),
      !0
    );
  }
  function xo(e, t, n) {
    var l = e.stateNode;
    if (!l) throw Error(a(169));
    (n
      ? ((e = po(e, t, hn)),
        (l.__reactInternalMemoizedMergedChildContext = e),
        ve(Ge),
        ve(He),
        pe(He, e))
      : ve(Ge),
      pe(Ge, n));
  }
  var Ft = null,
    E1 = !1,
    xi = !1;
  function Co(e) {
    Ft === null ? (Ft = [e]) : Ft.push(e);
  }
  function Z3(e) {
    ((E1 = !0), Co(e));
  }
  function Jt() {
    if (!xi && Ft !== null) {
      xi = !0;
      var e = 0,
        t = me;
      try {
        var n = Ft;
        for (me = 1; e < n.length; e++) {
          var l = n[e];
          do l = l(!0);
          while (l !== null);
        }
        ((Ft = null), (E1 = !1));
      } catch (o) {
        throw (Ft !== null && (Ft = Ft.slice(e + 1)), vs(Al, Jt), o);
      } finally {
        ((me = t), (xi = !1));
      }
    }
    return null;
  }
  var Zn = [],
    Wn = 0,
    S1 = null,
    k1 = 0,
    at = [],
    ut = 0,
    pn = null,
    It = 1,
    Dt = "";
  function xn(e, t) {
    ((Zn[Wn++] = k1), (Zn[Wn++] = S1), (S1 = e), (k1 = t));
  }
  function vo(e, t, n) {
    ((at[ut++] = It), (at[ut++] = Dt), (at[ut++] = pn), (pn = e));
    var l = It;
    e = Dt;
    var o = 32 - ht(l) - 1;
    ((l &= ~(1 << o)), (n += 1));
    var u = 32 - ht(t) + o;
    if (30 < u) {
      var f = o - (o % 5);
      ((u = (l & ((1 << f) - 1)).toString(32)),
        (l >>= f),
        (o -= f),
        (It = (1 << (32 - ht(t) + o)) | (n << o) | l),
        (Dt = u + e));
    } else ((It = (1 << u) | (n << o) | l), (Dt = e));
  }
  function Ci(e) {
    e.return !== null && (xn(e, 1), vo(e, 1, 0));
  }
  function vi(e) {
    for (; e === S1; )
      ((S1 = Zn[--Wn]), (Zn[Wn] = null), (k1 = Zn[--Wn]), (Zn[Wn] = null));
    for (; e === pn; )
      ((pn = at[--ut]),
        (at[ut] = null),
        (Dt = at[--ut]),
        (at[ut] = null),
        (It = at[--ut]),
        (at[ut] = null));
  }
  var rt = null,
    lt = null,
    we = !1,
    xt = null;
  function go(e, t) {
    var n = mt(5, null, null, 0);
    ((n.elementType = "DELETED"),
      (n.stateNode = t),
      (n.return = e),
      (t = e.deletions),
      t === null ? ((e.deletions = [n]), (e.flags |= 16)) : t.push(n));
  }
  function wo(e, t) {
    switch (e.tag) {
      case 5:
        var n = e.type;
        return (
          (t =
            t.nodeType !== 1 || n.toLowerCase() !== t.nodeName.toLowerCase()
              ? null
              : t),
          t !== null
            ? ((e.stateNode = t), (rt = e), (lt = Kt(t.firstChild)), !0)
            : !1
        );
      case 6:
        return (
          (t = e.pendingProps === "" || t.nodeType !== 3 ? null : t),
          t !== null ? ((e.stateNode = t), (rt = e), (lt = null), !0) : !1
        );
      case 13:
        return (
          (t = t.nodeType !== 8 ? null : t),
          t !== null
            ? ((n = pn !== null ? { id: It, overflow: Dt } : null),
              (e.memoizedState = {
                dehydrated: t,
                treeContext: n,
                retryLane: 1073741824,
              }),
              (n = mt(18, null, null, 0)),
              (n.stateNode = t),
              (n.return = e),
              (e.child = n),
              (rt = e),
              (lt = null),
              !0)
            : !1
        );
      default:
        return !1;
    }
  }
  function gi(e) {
    return (e.mode & 1) !== 0 && (e.flags & 128) === 0;
  }
  function wi(e) {
    if (we) {
      var t = lt;
      if (t) {
        var n = t;
        if (!wo(e, t)) {
          if (gi(e)) throw Error(a(418));
          t = Kt(n.nextSibling);
          var l = rt;
          t && wo(e, t)
            ? go(l, n)
            : ((e.flags = (e.flags & -4097) | 2), (we = !1), (rt = e));
        }
      } else {
        if (gi(e)) throw Error(a(418));
        ((e.flags = (e.flags & -4097) | 2), (we = !1), (rt = e));
      }
    }
  }
  function yo(e) {
    for (
      e = e.return;
      e !== null && e.tag !== 5 && e.tag !== 3 && e.tag !== 13;

    )
      e = e.return;
    rt = e;
  }
  function R1(e) {
    if (e !== rt) return !1;
    if (!we) return (yo(e), (we = !0), !1);
    var t;
    if (
      ((t = e.tag !== 3) &&
        !(t = e.tag !== 5) &&
        ((t = e.type),
        (t = t !== "head" && t !== "body" && !di(e.type, e.memoizedProps))),
      t && (t = lt))
    ) {
      if (gi(e)) throw (jo(), Error(a(418)));
      for (; t; ) (go(e, t), (t = Kt(t.nextSibling)));
    }
    if ((yo(e), e.tag === 13)) {
      if (((e = e.memoizedState), (e = e !== null ? e.dehydrated : null), !e))
        throw Error(a(317));
      e: {
        for (e = e.nextSibling, t = 0; e; ) {
          if (e.nodeType === 8) {
            var n = e.data;
            if (n === "/$") {
              if (t === 0) {
                lt = Kt(e.nextSibling);
                break e;
              }
              t--;
            } else (n !== "$" && n !== "$!" && n !== "$?") || t++;
          }
          e = e.nextSibling;
        }
        lt = null;
      }
    } else lt = rt ? Kt(e.stateNode.nextSibling) : null;
    return !0;
  }
  function jo() {
    for (var e = lt; e; ) e = Kt(e.nextSibling);
  }
  function $n() {
    ((lt = rt = null), (we = !1));
  }
  function yi(e) {
    xt === null ? (xt = [e]) : xt.push(e);
  }
  var W3 = Z.ReactCurrentBatchConfig;
  function _r(e, t, n) {
    if (
      ((e = n.ref),
      e !== null && typeof e != "function" && typeof e != "object")
    ) {
      if (n._owner) {
        if (((n = n._owner), n)) {
          if (n.tag !== 1) throw Error(a(309));
          var l = n.stateNode;
        }
        if (!l) throw Error(a(147, e));
        var o = l,
          u = "" + e;
        return t !== null &&
          t.ref !== null &&
          typeof t.ref == "function" &&
          t.ref._stringRef === u
          ? t.ref
          : ((t = function (f) {
              var C = o.refs;
              f === null ? delete C[u] : (C[u] = f);
            }),
            (t._stringRef = u),
            t);
      }
      if (typeof e != "string") throw Error(a(284));
      if (!n._owner) throw Error(a(290, e));
    }
    return e;
  }
  function M1(e, t) {
    throw (
      (e = Object.prototype.toString.call(t)),
      Error(
        a(
          31,
          e === "[object Object]"
            ? "object with keys {" + Object.keys(t).join(", ") + "}"
            : e,
        ),
      )
    );
  }
  function No(e) {
    var t = e._init;
    return t(e._payload);
  }
  function Lo(e) {
    function t(E, w) {
      if (e) {
        var S = E.deletions;
        S === null ? ((E.deletions = [w]), (E.flags |= 16)) : S.push(w);
      }
    }
    function n(E, w) {
      if (!e) return null;
      for (; w !== null; ) (t(E, w), (w = w.sibling));
      return null;
    }
    function l(E, w) {
      for (E = new Map(); w !== null; )
        (w.key !== null ? E.set(w.key, w) : E.set(w.index, w), (w = w.sibling));
      return E;
    }
    function o(E, w) {
      return ((E = on(E, w)), (E.index = 0), (E.sibling = null), E);
    }
    function u(E, w, S) {
      return (
        (E.index = S),
        e
          ? ((S = E.alternate),
            S !== null
              ? ((S = S.index), S < w ? ((E.flags |= 2), w) : S)
              : ((E.flags |= 2), w))
          : ((E.flags |= 1048576), w)
      );
    }
    function f(E) {
      return (e && E.alternate === null && (E.flags |= 2), E);
    }
    function C(E, w, S, B) {
      return w === null || w.tag !== 6
        ? ((w = f0(S, E.mode, B)), (w.return = E), w)
        : ((w = o(w, S)), (w.return = E), w);
    }
    function g(E, w, S, B) {
      var Q = S.type;
      return Q === Y
        ? D(E, w, S.props.children, B, S.key)
        : w !== null &&
            (w.elementType === Q ||
              (typeof Q == "object" &&
                Q !== null &&
                Q.$$typeof === Be &&
                No(Q) === w.type))
          ? ((B = o(w, S.props)), (B.ref = _r(E, w, S)), (B.return = E), B)
          : ((B = q1(S.type, S.key, S.props, null, E.mode, B)),
            (B.ref = _r(E, w, S)),
            (B.return = E),
            B);
    }
    function R(E, w, S, B) {
      return w === null ||
        w.tag !== 4 ||
        w.stateNode.containerInfo !== S.containerInfo ||
        w.stateNode.implementation !== S.implementation
        ? ((w = m0(S, E.mode, B)), (w.return = E), w)
        : ((w = o(w, S.children || [])), (w.return = E), w);
    }
    function D(E, w, S, B, Q) {
      return w === null || w.tag !== 7
        ? ((w = Ln(S, E.mode, B, Q)), (w.return = E), w)
        : ((w = o(w, S)), (w.return = E), w);
    }
    function A(E, w, S) {
      if ((typeof w == "string" && w !== "") || typeof w == "number")
        return ((w = f0("" + w, E.mode, S)), (w.return = E), w);
      if (typeof w == "object" && w !== null) {
        switch (w.$$typeof) {
          case ee:
            return (
              (S = q1(w.type, w.key, w.props, null, E.mode, S)),
              (S.ref = _r(E, null, w)),
              (S.return = E),
              S
            );
          case K:
            return ((w = m0(w, E.mode, S)), (w.return = E), w);
          case Be:
            var B = w._init;
            return A(E, B(w._payload), S);
        }
        if (ar(w) || q(w))
          return ((w = Ln(w, E.mode, S, null)), (w.return = E), w);
        M1(E, w);
      }
      return null;
    }
    function _(E, w, S, B) {
      var Q = w !== null ? w.key : null;
      if ((typeof S == "string" && S !== "") || typeof S == "number")
        return Q !== null ? null : C(E, w, "" + S, B);
      if (typeof S == "object" && S !== null) {
        switch (S.$$typeof) {
          case ee:
            return S.key === Q ? g(E, w, S, B) : null;
          case K:
            return S.key === Q ? R(E, w, S, B) : null;
          case Be:
            return ((Q = S._init), _(E, w, Q(S._payload), B));
        }
        if (ar(S) || q(S)) return Q !== null ? null : D(E, w, S, B, null);
        M1(E, S);
      }
      return null;
    }
    function z(E, w, S, B, Q) {
      if ((typeof B == "string" && B !== "") || typeof B == "number")
        return ((E = E.get(S) || null), C(w, E, "" + B, Q));
      if (typeof B == "object" && B !== null) {
        switch (B.$$typeof) {
          case ee:
            return (
              (E = E.get(B.key === null ? S : B.key) || null),
              g(w, E, B, Q)
            );
          case K:
            return (
              (E = E.get(B.key === null ? S : B.key) || null),
              R(w, E, B, Q)
            );
          case Be:
            var X = B._init;
            return z(E, w, S, X(B._payload), Q);
        }
        if (ar(B) || q(B)) return ((E = E.get(S) || null), D(w, E, B, Q, null));
        M1(w, B);
      }
      return null;
    }
    function $(E, w, S, B) {
      for (
        var Q = null, X = null, J = w, te = (w = 0), Ie = null;
        J !== null && te < S.length;
        te++
      ) {
        J.index > te ? ((Ie = J), (J = null)) : (Ie = J.sibling);
        var ce = _(E, J, S[te], B);
        if (ce === null) {
          J === null && (J = Ie);
          break;
        }
        (e && J && ce.alternate === null && t(E, J),
          (w = u(ce, w, te)),
          X === null ? (Q = ce) : (X.sibling = ce),
          (X = ce),
          (J = Ie));
      }
      if (te === S.length) return (n(E, J), we && xn(E, te), Q);
      if (J === null) {
        for (; te < S.length; te++)
          ((J = A(E, S[te], B)),
            J !== null &&
              ((w = u(J, w, te)),
              X === null ? (Q = J) : (X.sibling = J),
              (X = J)));
        return (we && xn(E, te), Q);
      }
      for (J = l(E, J); te < S.length; te++)
        ((Ie = z(J, E, te, S[te], B)),
          Ie !== null &&
            (e &&
              Ie.alternate !== null &&
              J.delete(Ie.key === null ? te : Ie.key),
            (w = u(Ie, w, te)),
            X === null ? (Q = Ie) : (X.sibling = Ie),
            (X = Ie)));
      return (
        e &&
          J.forEach(function (an) {
            return t(E, an);
          }),
        we && xn(E, te),
        Q
      );
    }
    function G(E, w, S, B) {
      var Q = q(S);
      if (typeof Q != "function") throw Error(a(150));
      if (((S = Q.call(S)), S == null)) throw Error(a(151));
      for (
        var X = (Q = null), J = w, te = (w = 0), Ie = null, ce = S.next();
        J !== null && !ce.done;
        te++, ce = S.next()
      ) {
        J.index > te ? ((Ie = J), (J = null)) : (Ie = J.sibling);
        var an = _(E, J, ce.value, B);
        if (an === null) {
          J === null && (J = Ie);
          break;
        }
        (e && J && an.alternate === null && t(E, J),
          (w = u(an, w, te)),
          X === null ? (Q = an) : (X.sibling = an),
          (X = an),
          (J = Ie));
      }
      if (ce.done) return (n(E, J), we && xn(E, te), Q);
      if (J === null) {
        for (; !ce.done; te++, ce = S.next())
          ((ce = A(E, ce.value, B)),
            ce !== null &&
              ((w = u(ce, w, te)),
              X === null ? (Q = ce) : (X.sibling = ce),
              (X = ce)));
        return (we && xn(E, te), Q);
      }
      for (J = l(E, J); !ce.done; te++, ce = S.next())
        ((ce = z(J, E, te, ce.value, B)),
          ce !== null &&
            (e &&
              ce.alternate !== null &&
              J.delete(ce.key === null ? te : ce.key),
            (w = u(ce, w, te)),
            X === null ? (Q = ce) : (X.sibling = ce),
            (X = ce)));
      return (
        e &&
          J.forEach(function (Lu) {
            return t(E, Lu);
          }),
        we && xn(E, te),
        Q
      );
    }
    function Se(E, w, S, B) {
      if (
        (typeof S == "object" &&
          S !== null &&
          S.type === Y &&
          S.key === null &&
          (S = S.props.children),
        typeof S == "object" && S !== null)
      ) {
        switch (S.$$typeof) {
          case ee:
            e: {
              for (var Q = S.key, X = w; X !== null; ) {
                if (X.key === Q) {
                  if (((Q = S.type), Q === Y)) {
                    if (X.tag === 7) {
                      (n(E, X.sibling),
                        (w = o(X, S.props.children)),
                        (w.return = E),
                        (E = w));
                      break e;
                    }
                  } else if (
                    X.elementType === Q ||
                    (typeof Q == "object" &&
                      Q !== null &&
                      Q.$$typeof === Be &&
                      No(Q) === X.type)
                  ) {
                    (n(E, X.sibling),
                      (w = o(X, S.props)),
                      (w.ref = _r(E, X, S)),
                      (w.return = E),
                      (E = w));
                    break e;
                  }
                  n(E, X);
                  break;
                } else t(E, X);
                X = X.sibling;
              }
              S.type === Y
                ? ((w = Ln(S.props.children, E.mode, B, S.key)),
                  (w.return = E),
                  (E = w))
                : ((B = q1(S.type, S.key, S.props, null, E.mode, B)),
                  (B.ref = _r(E, w, S)),
                  (B.return = E),
                  (E = B));
            }
            return f(E);
          case K:
            e: {
              for (X = S.key; w !== null; ) {
                if (w.key === X)
                  if (
                    w.tag === 4 &&
                    w.stateNode.containerInfo === S.containerInfo &&
                    w.stateNode.implementation === S.implementation
                  ) {
                    (n(E, w.sibling),
                      (w = o(w, S.children || [])),
                      (w.return = E),
                      (E = w));
                    break e;
                  } else {
                    n(E, w);
                    break;
                  }
                else t(E, w);
                w = w.sibling;
              }
              ((w = m0(S, E.mode, B)), (w.return = E), (E = w));
            }
            return f(E);
          case Be:
            return ((X = S._init), Se(E, w, X(S._payload), B));
        }
        if (ar(S)) return $(E, w, S, B);
        if (q(S)) return G(E, w, S, B);
        M1(E, S);
      }
      return (typeof S == "string" && S !== "") || typeof S == "number"
        ? ((S = "" + S),
          w !== null && w.tag === 6
            ? (n(E, w.sibling), (w = o(w, S)), (w.return = E), (E = w))
            : (n(E, w), (w = f0(S, E.mode, B)), (w.return = E), (E = w)),
          f(E))
        : n(E, w);
    }
    return Se;
  }
  var Gn = Lo(!0),
    Eo = Lo(!1),
    b1 = Yt(null),
    P1 = null,
    Qn = null,
    ji = null;
  function Ni() {
    ji = Qn = P1 = null;
  }
  function Li(e) {
    var t = b1.current;
    (ve(b1), (e._currentValue = t));
  }
  function Ei(e, t, n) {
    for (; e !== null; ) {
      var l = e.alternate;
      if (
        ((e.childLanes & t) !== t
          ? ((e.childLanes |= t), l !== null && (l.childLanes |= t))
          : l !== null && (l.childLanes & t) !== t && (l.childLanes |= t),
        e === n)
      )
        break;
      e = e.return;
    }
  }
  function Kn(e, t) {
    ((P1 = e),
      (ji = Qn = null),
      (e = e.dependencies),
      e !== null &&
        e.firstContext !== null &&
        ((e.lanes & t) !== 0 && (Ke = !0), (e.firstContext = null)));
  }
  function ct(e) {
    var t = e._currentValue;
    if (ji !== e)
      if (((e = { context: e, memoizedValue: t, next: null }), Qn === null)) {
        if (P1 === null) throw Error(a(308));
        ((Qn = e), (P1.dependencies = { lanes: 0, firstContext: e }));
      } else Qn = Qn.next = e;
    return t;
  }
  var Cn = null;
  function Si(e) {
    Cn === null ? (Cn = [e]) : Cn.push(e);
  }
  function So(e, t, n, l) {
    var o = t.interleaved;
    return (
      o === null ? ((n.next = n), Si(t)) : ((n.next = o.next), (o.next = n)),
      (t.interleaved = n),
      Tt(e, l)
    );
  }
  function Tt(e, t) {
    e.lanes |= t;
    var n = e.alternate;
    for (n !== null && (n.lanes |= t), n = e, e = e.return; e !== null; )
      ((e.childLanes |= t),
        (n = e.alternate),
        n !== null && (n.childLanes |= t),
        (n = e),
        (e = e.return));
    return n.tag === 3 ? n.stateNode : null;
  }
  var qt = !1;
  function ki(e) {
    e.updateQueue = {
      baseState: e.memoizedState,
      firstBaseUpdate: null,
      lastBaseUpdate: null,
      shared: { pending: null, interleaved: null, lanes: 0 },
      effects: null,
    };
  }
  function ko(e, t) {
    ((e = e.updateQueue),
      t.updateQueue === e &&
        (t.updateQueue = {
          baseState: e.baseState,
          firstBaseUpdate: e.firstBaseUpdate,
          lastBaseUpdate: e.lastBaseUpdate,
          shared: e.shared,
          effects: e.effects,
        }));
  }
  function At(e, t) {
    return {
      eventTime: e,
      lane: t,
      tag: 0,
      payload: null,
      callback: null,
      next: null,
    };
  }
  function en(e, t, n) {
    var l = e.updateQueue;
    if (l === null) return null;
    if (((l = l.shared), (oe & 2) !== 0)) {
      var o = l.pending;
      return (
        o === null ? (t.next = t) : ((t.next = o.next), (o.next = t)),
        (l.pending = t),
        Tt(e, n)
      );
    }
    return (
      (o = l.interleaved),
      o === null ? ((t.next = t), Si(l)) : ((t.next = o.next), (o.next = t)),
      (l.interleaved = t),
      Tt(e, n)
    );
  }
  function O1(e, t, n) {
    if (
      ((t = t.updateQueue), t !== null && ((t = t.shared), (n & 4194240) !== 0))
    ) {
      var l = t.lanes;
      ((l &= e.pendingLanes), (n |= l), (t.lanes = n), Vl(e, n));
    }
  }
  function Ro(e, t) {
    var n = e.updateQueue,
      l = e.alternate;
    if (l !== null && ((l = l.updateQueue), n === l)) {
      var o = null,
        u = null;
      if (((n = n.firstBaseUpdate), n !== null)) {
        do {
          var f = {
            eventTime: n.eventTime,
            lane: n.lane,
            tag: n.tag,
            payload: n.payload,
            callback: n.callback,
            next: null,
          };
          (u === null ? (o = u = f) : (u = u.next = f), (n = n.next));
        } while (n !== null);
        u === null ? (o = u = t) : (u = u.next = t);
      } else o = u = t;
      ((n = {
        baseState: l.baseState,
        firstBaseUpdate: o,
        lastBaseUpdate: u,
        shared: l.shared,
        effects: l.effects,
      }),
        (e.updateQueue = n));
      return;
    }
    ((e = n.lastBaseUpdate),
      e === null ? (n.firstBaseUpdate = t) : (e.next = t),
      (n.lastBaseUpdate = t));
  }
  function _1(e, t, n, l) {
    var o = e.updateQueue;
    qt = !1;
    var u = o.firstBaseUpdate,
      f = o.lastBaseUpdate,
      C = o.shared.pending;
    if (C !== null) {
      o.shared.pending = null;
      var g = C,
        R = g.next;
      ((g.next = null), f === null ? (u = R) : (f.next = R), (f = g));
      var D = e.alternate;
      D !== null &&
        ((D = D.updateQueue),
        (C = D.lastBaseUpdate),
        C !== f &&
          (C === null ? (D.firstBaseUpdate = R) : (C.next = R),
          (D.lastBaseUpdate = g)));
    }
    if (u !== null) {
      var A = o.baseState;
      ((f = 0), (D = R = g = null), (C = u));
      do {
        var _ = C.lane,
          z = C.eventTime;
        if ((l & _) === _) {
          D !== null &&
            (D = D.next =
              {
                eventTime: z,
                lane: 0,
                tag: C.tag,
                payload: C.payload,
                callback: C.callback,
                next: null,
              });
          e: {
            var $ = e,
              G = C;
            switch (((_ = t), (z = n), G.tag)) {
              case 1:
                if ((($ = G.payload), typeof $ == "function")) {
                  A = $.call(z, A, _);
                  break e;
                }
                A = $;
                break e;
              case 3:
                $.flags = ($.flags & -65537) | 128;
              case 0:
                if (
                  (($ = G.payload),
                  (_ = typeof $ == "function" ? $.call(z, A, _) : $),
                  _ == null)
                )
                  break e;
                A = W({}, A, _);
                break e;
              case 2:
                qt = !0;
            }
          }
          C.callback !== null &&
            C.lane !== 0 &&
            ((e.flags |= 64),
            (_ = o.effects),
            _ === null ? (o.effects = [C]) : _.push(C));
        } else
          ((z = {
            eventTime: z,
            lane: _,
            tag: C.tag,
            payload: C.payload,
            callback: C.callback,
            next: null,
          }),
            D === null ? ((R = D = z), (g = A)) : (D = D.next = z),
            (f |= _));
        if (((C = C.next), C === null)) {
          if (((C = o.shared.pending), C === null)) break;
          ((_ = C),
            (C = _.next),
            (_.next = null),
            (o.lastBaseUpdate = _),
            (o.shared.pending = null));
        }
      } while (!0);
      if (
        (D === null && (g = A),
        (o.baseState = g),
        (o.firstBaseUpdate = R),
        (o.lastBaseUpdate = D),
        (t = o.shared.interleaved),
        t !== null)
      ) {
        o = t;
        do ((f |= o.lane), (o = o.next));
        while (o !== t);
      } else u === null && (o.shared.lanes = 0);
      ((wn |= f), (e.lanes = f), (e.memoizedState = A));
    }
  }
  function Mo(e, t, n) {
    if (((e = t.effects), (t.effects = null), e !== null))
      for (t = 0; t < e.length; t++) {
        var l = e[t],
          o = l.callback;
        if (o !== null) {
          if (((l.callback = null), (l = n), typeof o != "function"))
            throw Error(a(191, o));
          o.call(l);
        }
      }
  }
  var Fr = {},
    Mt = Yt(Fr),
    Ir = Yt(Fr),
    Dr = Yt(Fr);
  function vn(e) {
    if (e === Fr) throw Error(a(174));
    return e;
  }
  function Ri(e, t) {
    switch ((pe(Dr, t), pe(Ir, e), pe(Mt, Fr), (e = t.nodeType), e)) {
      case 9:
      case 11:
        t = (t = t.documentElement) ? t.namespaceURI : Ml(null, "");
        break;
      default:
        ((e = e === 8 ? t.parentNode : t),
          (t = e.namespaceURI || null),
          (e = e.tagName),
          (t = Ml(t, e)));
    }
    (ve(Mt), pe(Mt, t));
  }
  function Yn() {
    (ve(Mt), ve(Ir), ve(Dr));
  }
  function bo(e) {
    vn(Dr.current);
    var t = vn(Mt.current),
      n = Ml(t, e.type);
    t !== n && (pe(Ir, e), pe(Mt, n));
  }
  function Mi(e) {
    Ir.current === e && (ve(Mt), ve(Ir));
  }
  var ye = Yt(0);
  function F1(e) {
    for (var t = e; t !== null; ) {
      if (t.tag === 13) {
        var n = t.memoizedState;
        if (
          n !== null &&
          ((n = n.dehydrated), n === null || n.data === "$?" || n.data === "$!")
        )
          return t;
      } else if (t.tag === 19 && t.memoizedProps.revealOrder !== void 0) {
        if ((t.flags & 128) !== 0) return t;
      } else if (t.child !== null) {
        ((t.child.return = t), (t = t.child));
        continue;
      }
      if (t === e) break;
      for (; t.sibling === null; ) {
        if (t.return === null || t.return === e) return null;
        t = t.return;
      }
      ((t.sibling.return = t.return), (t = t.sibling));
    }
    return null;
  }
  var bi = [];
  function Pi() {
    for (var e = 0; e < bi.length; e++)
      bi[e]._workInProgressVersionPrimary = null;
    bi.length = 0;
  }
  var I1 = Z.ReactCurrentDispatcher,
    Oi = Z.ReactCurrentBatchConfig,
    gn = 0,
    je = null,
    Re = null,
    _e = null,
    D1 = !1,
    Tr = !1,
    Ar = 0,
    $3 = 0;
  function Ve() {
    throw Error(a(321));
  }
  function _i(e, t) {
    if (t === null) return !1;
    for (var n = 0; n < t.length && n < e.length; n++)
      if (!pt(e[n], t[n])) return !1;
    return !0;
  }
  function Fi(e, t, n, l, o, u) {
    if (
      ((gn = u),
      (je = t),
      (t.memoizedState = null),
      (t.updateQueue = null),
      (t.lanes = 0),
      (I1.current = e === null || e.memoizedState === null ? Y3 : X3),
      (e = n(l, o)),
      Tr)
    ) {
      u = 0;
      do {
        if (((Tr = !1), (Ar = 0), 25 <= u)) throw Error(a(301));
        ((u += 1),
          (_e = Re = null),
          (t.updateQueue = null),
          (I1.current = J3),
          (e = n(l, o)));
      } while (Tr);
    }
    if (
      ((I1.current = B1),
      (t = Re !== null && Re.next !== null),
      (gn = 0),
      (_e = Re = je = null),
      (D1 = !1),
      t)
    )
      throw Error(a(300));
    return e;
  }
  function Ii() {
    var e = Ar !== 0;
    return ((Ar = 0), e);
  }
  function bt() {
    var e = {
      memoizedState: null,
      baseState: null,
      baseQueue: null,
      queue: null,
      next: null,
    };
    return (_e === null ? (je.memoizedState = _e = e) : (_e = _e.next = e), _e);
  }
  function dt() {
    if (Re === null) {
      var e = je.alternate;
      e = e !== null ? e.memoizedState : null;
    } else e = Re.next;
    var t = _e === null ? je.memoizedState : _e.next;
    if (t !== null) ((_e = t), (Re = e));
    else {
      if (e === null) throw Error(a(310));
      ((Re = e),
        (e = {
          memoizedState: Re.memoizedState,
          baseState: Re.baseState,
          baseQueue: Re.baseQueue,
          queue: Re.queue,
          next: null,
        }),
        _e === null ? (je.memoizedState = _e = e) : (_e = _e.next = e));
    }
    return _e;
  }
  function Br(e, t) {
    return typeof t == "function" ? t(e) : t;
  }
  function Di(e) {
    var t = dt(),
      n = t.queue;
    if (n === null) throw Error(a(311));
    n.lastRenderedReducer = e;
    var l = Re,
      o = l.baseQueue,
      u = n.pending;
    if (u !== null) {
      if (o !== null) {
        var f = o.next;
        ((o.next = u.next), (u.next = f));
      }
      ((l.baseQueue = o = u), (n.pending = null));
    }
    if (o !== null) {
      ((u = o.next), (l = l.baseState));
      var C = (f = null),
        g = null,
        R = u;
      do {
        var D = R.lane;
        if ((gn & D) === D)
          (g !== null &&
            (g = g.next =
              {
                lane: 0,
                action: R.action,
                hasEagerState: R.hasEagerState,
                eagerState: R.eagerState,
                next: null,
              }),
            (l = R.hasEagerState ? R.eagerState : e(l, R.action)));
        else {
          var A = {
            lane: D,
            action: R.action,
            hasEagerState: R.hasEagerState,
            eagerState: R.eagerState,
            next: null,
          };
          (g === null ? ((C = g = A), (f = l)) : (g = g.next = A),
            (je.lanes |= D),
            (wn |= D));
        }
        R = R.next;
      } while (R !== null && R !== u);
      (g === null ? (f = l) : (g.next = C),
        pt(l, t.memoizedState) || (Ke = !0),
        (t.memoizedState = l),
        (t.baseState = f),
        (t.baseQueue = g),
        (n.lastRenderedState = l));
    }
    if (((e = n.interleaved), e !== null)) {
      o = e;
      do ((u = o.lane), (je.lanes |= u), (wn |= u), (o = o.next));
      while (o !== e);
    } else o === null && (n.lanes = 0);
    return [t.memoizedState, n.dispatch];
  }
  function Ti(e) {
    var t = dt(),
      n = t.queue;
    if (n === null) throw Error(a(311));
    n.lastRenderedReducer = e;
    var l = n.dispatch,
      o = n.pending,
      u = t.memoizedState;
    if (o !== null) {
      n.pending = null;
      var f = (o = o.next);
      do ((u = e(u, f.action)), (f = f.next));
      while (f !== o);
      (pt(u, t.memoizedState) || (Ke = !0),
        (t.memoizedState = u),
        t.baseQueue === null && (t.baseState = u),
        (n.lastRenderedState = u));
    }
    return [u, l];
  }
  function Po() {}
  function Oo(e, t) {
    var n = je,
      l = dt(),
      o = t(),
      u = !pt(l.memoizedState, o);
    if (
      (u && ((l.memoizedState = o), (Ke = !0)),
      (l = l.queue),
      Ai(Io.bind(null, n, l, e), [e]),
      l.getSnapshot !== t || u || (_e !== null && _e.memoizedState.tag & 1))
    ) {
      if (
        ((n.flags |= 2048),
        Hr(9, Fo.bind(null, n, l, o, t), void 0, null),
        Fe === null)
      )
        throw Error(a(349));
      (gn & 30) !== 0 || _o(n, t, o);
    }
    return o;
  }
  function _o(e, t, n) {
    ((e.flags |= 16384),
      (e = { getSnapshot: t, value: n }),
      (t = je.updateQueue),
      t === null
        ? ((t = { lastEffect: null, stores: null }),
          (je.updateQueue = t),
          (t.stores = [e]))
        : ((n = t.stores), n === null ? (t.stores = [e]) : n.push(e)));
  }
  function Fo(e, t, n, l) {
    ((t.value = n), (t.getSnapshot = l), Do(t) && To(e));
  }
  function Io(e, t, n) {
    return n(function () {
      Do(t) && To(e);
    });
  }
  function Do(e) {
    var t = e.getSnapshot;
    e = e.value;
    try {
      var n = t();
      return !pt(e, n);
    } catch {
      return !0;
    }
  }
  function To(e) {
    var t = Tt(e, 1);
    t !== null && wt(t, e, 1, -1);
  }
  function Ao(e) {
    var t = bt();
    return (
      typeof e == "function" && (e = e()),
      (t.memoizedState = t.baseState = e),
      (e = {
        pending: null,
        interleaved: null,
        lanes: 0,
        dispatch: null,
        lastRenderedReducer: Br,
        lastRenderedState: e,
      }),
      (t.queue = e),
      (e = e.dispatch = K3.bind(null, je, e)),
      [t.memoizedState, e]
    );
  }
  function Hr(e, t, n, l) {
    return (
      (e = { tag: e, create: t, destroy: n, deps: l, next: null }),
      (t = je.updateQueue),
      t === null
        ? ((t = { lastEffect: null, stores: null }),
          (je.updateQueue = t),
          (t.lastEffect = e.next = e))
        : ((n = t.lastEffect),
          n === null
            ? (t.lastEffect = e.next = e)
            : ((l = n.next), (n.next = e), (e.next = l), (t.lastEffect = e))),
      e
    );
  }
  function Bo() {
    return dt().memoizedState;
  }
  function T1(e, t, n, l) {
    var o = bt();
    ((je.flags |= e),
      (o.memoizedState = Hr(1 | t, n, void 0, l === void 0 ? null : l)));
  }
  function A1(e, t, n, l) {
    var o = dt();
    l = l === void 0 ? null : l;
    var u = void 0;
    if (Re !== null) {
      var f = Re.memoizedState;
      if (((u = f.destroy), l !== null && _i(l, f.deps))) {
        o.memoizedState = Hr(t, n, u, l);
        return;
      }
    }
    ((je.flags |= e), (o.memoizedState = Hr(1 | t, n, u, l)));
  }
  function Ho(e, t) {
    return T1(8390656, 8, e, t);
  }
  function Ai(e, t) {
    return A1(2048, 8, e, t);
  }
  function Vo(e, t) {
    return A1(4, 2, e, t);
  }
  function zo(e, t) {
    return A1(4, 4, e, t);
  }
  function Uo(e, t) {
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
  function Zo(e, t, n) {
    return (
      (n = n != null ? n.concat([e]) : null),
      A1(4, 4, Uo.bind(null, t, e), n)
    );
  }
  function Bi() {}
  function Wo(e, t) {
    var n = dt();
    t = t === void 0 ? null : t;
    var l = n.memoizedState;
    return l !== null && t !== null && _i(t, l[1])
      ? l[0]
      : ((n.memoizedState = [e, t]), e);
  }
  function $o(e, t) {
    var n = dt();
    t = t === void 0 ? null : t;
    var l = n.memoizedState;
    return l !== null && t !== null && _i(t, l[1])
      ? l[0]
      : ((e = e()), (n.memoizedState = [e, t]), e);
  }
  function Go(e, t, n) {
    return (gn & 21) === 0
      ? (e.baseState && ((e.baseState = !1), (Ke = !0)), (e.memoizedState = n))
      : (pt(n, t) ||
          ((n = js()), (je.lanes |= n), (wn |= n), (e.baseState = !0)),
        t);
  }
  function G3(e, t) {
    var n = me;
    ((me = n !== 0 && 4 > n ? n : 4), e(!0));
    var l = Oi.transition;
    Oi.transition = {};
    try {
      (e(!1), t());
    } finally {
      ((me = n), (Oi.transition = l));
    }
  }
  function Qo() {
    return dt().memoizedState;
  }
  function Q3(e, t, n) {
    var l = ln(e);
    if (
      ((n = {
        lane: l,
        action: n,
        hasEagerState: !1,
        eagerState: null,
        next: null,
      }),
      Ko(e))
    )
      Yo(t, n);
    else if (((n = So(e, t, n, l)), n !== null)) {
      var o = $e();
      (wt(n, e, l, o), Xo(n, t, l));
    }
  }
  function K3(e, t, n) {
    var l = ln(e),
      o = {
        lane: l,
        action: n,
        hasEagerState: !1,
        eagerState: null,
        next: null,
      };
    if (Ko(e)) Yo(t, o);
    else {
      var u = e.alternate;
      if (
        e.lanes === 0 &&
        (u === null || u.lanes === 0) &&
        ((u = t.lastRenderedReducer), u !== null)
      )
        try {
          var f = t.lastRenderedState,
            C = u(f, n);
          if (((o.hasEagerState = !0), (o.eagerState = C), pt(C, f))) {
            var g = t.interleaved;
            (g === null
              ? ((o.next = o), Si(t))
              : ((o.next = g.next), (g.next = o)),
              (t.interleaved = o));
            return;
          }
        } catch {
        } finally {
        }
      ((n = So(e, t, o, l)),
        n !== null && ((o = $e()), wt(n, e, l, o), Xo(n, t, l)));
    }
  }
  function Ko(e) {
    var t = e.alternate;
    return e === je || (t !== null && t === je);
  }
  function Yo(e, t) {
    Tr = D1 = !0;
    var n = e.pending;
    (n === null ? (t.next = t) : ((t.next = n.next), (n.next = t)),
      (e.pending = t));
  }
  function Xo(e, t, n) {
    if ((n & 4194240) !== 0) {
      var l = t.lanes;
      ((l &= e.pendingLanes), (n |= l), (t.lanes = n), Vl(e, n));
    }
  }
  var B1 = {
      readContext: ct,
      useCallback: Ve,
      useContext: Ve,
      useEffect: Ve,
      useImperativeHandle: Ve,
      useInsertionEffect: Ve,
      useLayoutEffect: Ve,
      useMemo: Ve,
      useReducer: Ve,
      useRef: Ve,
      useState: Ve,
      useDebugValue: Ve,
      useDeferredValue: Ve,
      useTransition: Ve,
      useMutableSource: Ve,
      useSyncExternalStore: Ve,
      useId: Ve,
      unstable_isNewReconciler: !1,
    },
    Y3 = {
      readContext: ct,
      useCallback: function (e, t) {
        return ((bt().memoizedState = [e, t === void 0 ? null : t]), e);
      },
      useContext: ct,
      useEffect: Ho,
      useImperativeHandle: function (e, t, n) {
        return (
          (n = n != null ? n.concat([e]) : null),
          T1(4194308, 4, Uo.bind(null, t, e), n)
        );
      },
      useLayoutEffect: function (e, t) {
        return T1(4194308, 4, e, t);
      },
      useInsertionEffect: function (e, t) {
        return T1(4, 2, e, t);
      },
      useMemo: function (e, t) {
        var n = bt();
        return (
          (t = t === void 0 ? null : t),
          (e = e()),
          (n.memoizedState = [e, t]),
          e
        );
      },
      useReducer: function (e, t, n) {
        var l = bt();
        return (
          (t = n !== void 0 ? n(t) : t),
          (l.memoizedState = l.baseState = t),
          (e = {
            pending: null,
            interleaved: null,
            lanes: 0,
            dispatch: null,
            lastRenderedReducer: e,
            lastRenderedState: t,
          }),
          (l.queue = e),
          (e = e.dispatch = Q3.bind(null, je, e)),
          [l.memoizedState, e]
        );
      },
      useRef: function (e) {
        var t = bt();
        return ((e = { current: e }), (t.memoizedState = e));
      },
      useState: Ao,
      useDebugValue: Bi,
      useDeferredValue: function (e) {
        return (bt().memoizedState = e);
      },
      useTransition: function () {
        var e = Ao(!1),
          t = e[0];
        return ((e = G3.bind(null, e[1])), (bt().memoizedState = e), [t, e]);
      },
      useMutableSource: function () {},
      useSyncExternalStore: function (e, t, n) {
        var l = je,
          o = bt();
        if (we) {
          if (n === void 0) throw Error(a(407));
          n = n();
        } else {
          if (((n = t()), Fe === null)) throw Error(a(349));
          (gn & 30) !== 0 || _o(l, t, n);
        }
        o.memoizedState = n;
        var u = { value: n, getSnapshot: t };
        return (
          (o.queue = u),
          Ho(Io.bind(null, l, u, e), [e]),
          (l.flags |= 2048),
          Hr(9, Fo.bind(null, l, u, n, t), void 0, null),
          n
        );
      },
      useId: function () {
        var e = bt(),
          t = Fe.identifierPrefix;
        if (we) {
          var n = Dt,
            l = It;
          ((n = (l & ~(1 << (32 - ht(l) - 1))).toString(32) + n),
            (t = ":" + t + "R" + n),
            (n = Ar++),
            0 < n && (t += "H" + n.toString(32)),
            (t += ":"));
        } else ((n = $3++), (t = ":" + t + "r" + n.toString(32) + ":"));
        return (e.memoizedState = t);
      },
      unstable_isNewReconciler: !1,
    },
    X3 = {
      readContext: ct,
      useCallback: Wo,
      useContext: ct,
      useEffect: Ai,
      useImperativeHandle: Zo,
      useInsertionEffect: Vo,
      useLayoutEffect: zo,
      useMemo: $o,
      useReducer: Di,
      useRef: Bo,
      useState: function () {
        return Di(Br);
      },
      useDebugValue: Bi,
      useDeferredValue: function (e) {
        var t = dt();
        return Go(t, Re.memoizedState, e);
      },
      useTransition: function () {
        var e = Di(Br)[0],
          t = dt().memoizedState;
        return [e, t];
      },
      useMutableSource: Po,
      useSyncExternalStore: Oo,
      useId: Qo,
      unstable_isNewReconciler: !1,
    },
    J3 = {
      readContext: ct,
      useCallback: Wo,
      useContext: ct,
      useEffect: Ai,
      useImperativeHandle: Zo,
      useInsertionEffect: Vo,
      useLayoutEffect: zo,
      useMemo: $o,
      useReducer: Ti,
      useRef: Bo,
      useState: function () {
        return Ti(Br);
      },
      useDebugValue: Bi,
      useDeferredValue: function (e) {
        var t = dt();
        return Re === null ? (t.memoizedState = e) : Go(t, Re.memoizedState, e);
      },
      useTransition: function () {
        var e = Ti(Br)[0],
          t = dt().memoizedState;
        return [e, t];
      },
      useMutableSource: Po,
      useSyncExternalStore: Oo,
      useId: Qo,
      unstable_isNewReconciler: !1,
    };
  function Ct(e, t) {
    if (e && e.defaultProps) {
      ((t = W({}, t)), (e = e.defaultProps));
      for (var n in e) t[n] === void 0 && (t[n] = e[n]);
      return t;
    }
    return t;
  }
  function Hi(e, t, n, l) {
    ((t = e.memoizedState),
      (n = n(l, t)),
      (n = n == null ? t : W({}, t, n)),
      (e.memoizedState = n),
      e.lanes === 0 && (e.updateQueue.baseState = n));
  }
  var H1 = {
    isMounted: function (e) {
      return (e = e._reactInternals) ? fn(e) === e : !1;
    },
    enqueueSetState: function (e, t, n) {
      e = e._reactInternals;
      var l = $e(),
        o = ln(e),
        u = At(l, o);
      ((u.payload = t),
        n != null && (u.callback = n),
        (t = en(e, u, o)),
        t !== null && (wt(t, e, o, l), O1(t, e, o)));
    },
    enqueueReplaceState: function (e, t, n) {
      e = e._reactInternals;
      var l = $e(),
        o = ln(e),
        u = At(l, o);
      ((u.tag = 1),
        (u.payload = t),
        n != null && (u.callback = n),
        (t = en(e, u, o)),
        t !== null && (wt(t, e, o, l), O1(t, e, o)));
    },
    enqueueForceUpdate: function (e, t) {
      e = e._reactInternals;
      var n = $e(),
        l = ln(e),
        o = At(n, l);
      ((o.tag = 2),
        t != null && (o.callback = t),
        (t = en(e, o, l)),
        t !== null && (wt(t, e, l, n), O1(t, e, l)));
    },
  };
  function Jo(e, t, n, l, o, u, f) {
    return (
      (e = e.stateNode),
      typeof e.shouldComponentUpdate == "function"
        ? e.shouldComponentUpdate(l, u, f)
        : t.prototype && t.prototype.isPureReactComponent
          ? !Sr(n, l) || !Sr(o, u)
          : !0
    );
  }
  function qo(e, t, n) {
    var l = !1,
      o = Xt,
      u = t.contextType;
    return (
      typeof u == "object" && u !== null
        ? (u = ct(u))
        : ((o = Qe(t) ? hn : He.current),
          (l = t.contextTypes),
          (u = (l = l != null) ? Un(e, o) : Xt)),
      (t = new t(n, u)),
      (e.memoizedState =
        t.state !== null && t.state !== void 0 ? t.state : null),
      (t.updater = H1),
      (e.stateNode = t),
      (t._reactInternals = e),
      l &&
        ((e = e.stateNode),
        (e.__reactInternalMemoizedUnmaskedChildContext = o),
        (e.__reactInternalMemoizedMaskedChildContext = u)),
      t
    );
  }
  function e2(e, t, n, l) {
    ((e = t.state),
      typeof t.componentWillReceiveProps == "function" &&
        t.componentWillReceiveProps(n, l),
      typeof t.UNSAFE_componentWillReceiveProps == "function" &&
        t.UNSAFE_componentWillReceiveProps(n, l),
      t.state !== e && H1.enqueueReplaceState(t, t.state, null));
  }
  function Vi(e, t, n, l) {
    var o = e.stateNode;
    ((o.props = n), (o.state = e.memoizedState), (o.refs = {}), ki(e));
    var u = t.contextType;
    (typeof u == "object" && u !== null
      ? (o.context = ct(u))
      : ((u = Qe(t) ? hn : He.current), (o.context = Un(e, u))),
      (o.state = e.memoizedState),
      (u = t.getDerivedStateFromProps),
      typeof u == "function" && (Hi(e, t, u, n), (o.state = e.memoizedState)),
      typeof t.getDerivedStateFromProps == "function" ||
        typeof o.getSnapshotBeforeUpdate == "function" ||
        (typeof o.UNSAFE_componentWillMount != "function" &&
          typeof o.componentWillMount != "function") ||
        ((t = o.state),
        typeof o.componentWillMount == "function" && o.componentWillMount(),
        typeof o.UNSAFE_componentWillMount == "function" &&
          o.UNSAFE_componentWillMount(),
        t !== o.state && H1.enqueueReplaceState(o, o.state, null),
        _1(e, n, o, l),
        (o.state = e.memoizedState)),
      typeof o.componentDidMount == "function" && (e.flags |= 4194308));
  }
  function Xn(e, t) {
    try {
      var n = "",
        l = t;
      do ((n += ae(l)), (l = l.return));
      while (l);
      var o = n;
    } catch (u) {
      o =
        `
Error generating stack: ` +
        u.message +
        `
` +
        u.stack;
    }
    return { value: e, source: t, stack: o, digest: null };
  }
  function zi(e, t, n) {
    return { value: e, source: null, stack: n ?? null, digest: t ?? null };
  }
  function Ui(e, t) {
    try {
      console.error(t.value);
    } catch (n) {
      setTimeout(function () {
        throw n;
      });
    }
  }
  var q3 = typeof WeakMap == "function" ? WeakMap : Map;
  function t2(e, t, n) {
    ((n = At(-1, n)), (n.tag = 3), (n.payload = { element: null }));
    var l = t.value;
    return (
      (n.callback = function () {
        (G1 || ((G1 = !0), (l0 = l)), Ui(e, t));
      }),
      n
    );
  }
  function n2(e, t, n) {
    ((n = At(-1, n)), (n.tag = 3));
    var l = e.type.getDerivedStateFromError;
    if (typeof l == "function") {
      var o = t.value;
      ((n.payload = function () {
        return l(o);
      }),
        (n.callback = function () {
          Ui(e, t);
        }));
    }
    var u = e.stateNode;
    return (
      u !== null &&
        typeof u.componentDidCatch == "function" &&
        (n.callback = function () {
          (Ui(e, t),
            typeof l != "function" &&
              (nn === null ? (nn = new Set([this])) : nn.add(this)));
          var f = t.stack;
          this.componentDidCatch(t.value, {
            componentStack: f !== null ? f : "",
          });
        }),
      n
    );
  }
  function r2(e, t, n) {
    var l = e.pingCache;
    if (l === null) {
      l = e.pingCache = new q3();
      var o = new Set();
      l.set(t, o);
    } else ((o = l.get(t)), o === void 0 && ((o = new Set()), l.set(t, o)));
    o.has(n) || (o.add(n), (e = mu.bind(null, e, t, n)), t.then(e, e));
  }
  function l2(e) {
    do {
      var t;
      if (
        ((t = e.tag === 13) &&
          ((t = e.memoizedState),
          (t = t !== null ? t.dehydrated !== null : !0)),
        t)
      )
        return e;
      e = e.return;
    } while (e !== null);
    return null;
  }
  function i2(e, t, n, l, o) {
    return (e.mode & 1) === 0
      ? (e === t
          ? (e.flags |= 65536)
          : ((e.flags |= 128),
            (n.flags |= 131072),
            (n.flags &= -52805),
            n.tag === 1 &&
              (n.alternate === null
                ? (n.tag = 17)
                : ((t = At(-1, 1)), (t.tag = 2), en(n, t, 1))),
            (n.lanes |= 1)),
        e)
      : ((e.flags |= 65536), (e.lanes = o), e);
  }
  var eu = Z.ReactCurrentOwner,
    Ke = !1;
  function We(e, t, n, l) {
    t.child = e === null ? Eo(t, null, n, l) : Gn(t, e.child, n, l);
  }
  function s2(e, t, n, l, o) {
    n = n.render;
    var u = t.ref;
    return (
      Kn(t, o),
      (l = Fi(e, t, n, l, u, o)),
      (n = Ii()),
      e !== null && !Ke
        ? ((t.updateQueue = e.updateQueue),
          (t.flags &= -2053),
          (e.lanes &= ~o),
          Bt(e, t, o))
        : (we && n && Ci(t), (t.flags |= 1), We(e, t, l, o), t.child)
    );
  }
  function o2(e, t, n, l, o) {
    if (e === null) {
      var u = n.type;
      return typeof u == "function" &&
        !d0(u) &&
        u.defaultProps === void 0 &&
        n.compare === null &&
        n.defaultProps === void 0
        ? ((t.tag = 15), (t.type = u), a2(e, t, u, l, o))
        : ((e = q1(n.type, null, l, t, t.mode, o)),
          (e.ref = t.ref),
          (e.return = t),
          (t.child = e));
    }
    if (((u = e.child), (e.lanes & o) === 0)) {
      var f = u.memoizedProps;
      if (
        ((n = n.compare), (n = n !== null ? n : Sr), n(f, l) && e.ref === t.ref)
      )
        return Bt(e, t, o);
    }
    return (
      (t.flags |= 1),
      (e = on(u, l)),
      (e.ref = t.ref),
      (e.return = t),
      (t.child = e)
    );
  }
  function a2(e, t, n, l, o) {
    if (e !== null) {
      var u = e.memoizedProps;
      if (Sr(u, l) && e.ref === t.ref)
        if (((Ke = !1), (t.pendingProps = l = u), (e.lanes & o) !== 0))
          (e.flags & 131072) !== 0 && (Ke = !0);
        else return ((t.lanes = e.lanes), Bt(e, t, o));
    }
    return Zi(e, t, n, l, o);
  }
  function u2(e, t, n) {
    var l = t.pendingProps,
      o = l.children,
      u = e !== null ? e.memoizedState : null;
    if (l.mode === "hidden")
      if ((t.mode & 1) === 0)
        ((t.memoizedState = {
          baseLanes: 0,
          cachePool: null,
          transitions: null,
        }),
          pe(qn, it),
          (it |= n));
      else {
        if ((n & 1073741824) === 0)
          return (
            (e = u !== null ? u.baseLanes | n : n),
            (t.lanes = t.childLanes = 1073741824),
            (t.memoizedState = {
              baseLanes: e,
              cachePool: null,
              transitions: null,
            }),
            (t.updateQueue = null),
            pe(qn, it),
            (it |= e),
            null
          );
        ((t.memoizedState = {
          baseLanes: 0,
          cachePool: null,
          transitions: null,
        }),
          (l = u !== null ? u.baseLanes : n),
          pe(qn, it),
          (it |= l));
      }
    else
      (u !== null ? ((l = u.baseLanes | n), (t.memoizedState = null)) : (l = n),
        pe(qn, it),
        (it |= l));
    return (We(e, t, o, n), t.child);
  }
  function c2(e, t) {
    var n = t.ref;
    ((e === null && n !== null) || (e !== null && e.ref !== n)) &&
      ((t.flags |= 512), (t.flags |= 2097152));
  }
  function Zi(e, t, n, l, o) {
    var u = Qe(n) ? hn : He.current;
    return (
      (u = Un(t, u)),
      Kn(t, o),
      (n = Fi(e, t, n, l, u, o)),
      (l = Ii()),
      e !== null && !Ke
        ? ((t.updateQueue = e.updateQueue),
          (t.flags &= -2053),
          (e.lanes &= ~o),
          Bt(e, t, o))
        : (we && l && Ci(t), (t.flags |= 1), We(e, t, n, o), t.child)
    );
  }
  function d2(e, t, n, l, o) {
    if (Qe(n)) {
      var u = !0;
      L1(t);
    } else u = !1;
    if ((Kn(t, o), t.stateNode === null))
      (z1(e, t), qo(t, n, l), Vi(t, n, l, o), (l = !0));
    else if (e === null) {
      var f = t.stateNode,
        C = t.memoizedProps;
      f.props = C;
      var g = f.context,
        R = n.contextType;
      typeof R == "object" && R !== null
        ? (R = ct(R))
        : ((R = Qe(n) ? hn : He.current), (R = Un(t, R)));
      var D = n.getDerivedStateFromProps,
        A =
          typeof D == "function" ||
          typeof f.getSnapshotBeforeUpdate == "function";
      (A ||
        (typeof f.UNSAFE_componentWillReceiveProps != "function" &&
          typeof f.componentWillReceiveProps != "function") ||
        ((C !== l || g !== R) && e2(t, f, l, R)),
        (qt = !1));
      var _ = t.memoizedState;
      ((f.state = _),
        _1(t, l, f, o),
        (g = t.memoizedState),
        C !== l || _ !== g || Ge.current || qt
          ? (typeof D == "function" && (Hi(t, n, D, l), (g = t.memoizedState)),
            (C = qt || Jo(t, n, C, l, _, g, R))
              ? (A ||
                  (typeof f.UNSAFE_componentWillMount != "function" &&
                    typeof f.componentWillMount != "function") ||
                  (typeof f.componentWillMount == "function" &&
                    f.componentWillMount(),
                  typeof f.UNSAFE_componentWillMount == "function" &&
                    f.UNSAFE_componentWillMount()),
                typeof f.componentDidMount == "function" &&
                  (t.flags |= 4194308))
              : (typeof f.componentDidMount == "function" &&
                  (t.flags |= 4194308),
                (t.memoizedProps = l),
                (t.memoizedState = g)),
            (f.props = l),
            (f.state = g),
            (f.context = R),
            (l = C))
          : (typeof f.componentDidMount == "function" && (t.flags |= 4194308),
            (l = !1)));
    } else {
      ((f = t.stateNode),
        ko(e, t),
        (C = t.memoizedProps),
        (R = t.type === t.elementType ? C : Ct(t.type, C)),
        (f.props = R),
        (A = t.pendingProps),
        (_ = f.context),
        (g = n.contextType),
        typeof g == "object" && g !== null
          ? (g = ct(g))
          : ((g = Qe(n) ? hn : He.current), (g = Un(t, g))));
      var z = n.getDerivedStateFromProps;
      ((D =
        typeof z == "function" ||
        typeof f.getSnapshotBeforeUpdate == "function") ||
        (typeof f.UNSAFE_componentWillReceiveProps != "function" &&
          typeof f.componentWillReceiveProps != "function") ||
        ((C !== A || _ !== g) && e2(t, f, l, g)),
        (qt = !1),
        (_ = t.memoizedState),
        (f.state = _),
        _1(t, l, f, o));
      var $ = t.memoizedState;
      C !== A || _ !== $ || Ge.current || qt
        ? (typeof z == "function" && (Hi(t, n, z, l), ($ = t.memoizedState)),
          (R = qt || Jo(t, n, R, l, _, $, g) || !1)
            ? (D ||
                (typeof f.UNSAFE_componentWillUpdate != "function" &&
                  typeof f.componentWillUpdate != "function") ||
                (typeof f.componentWillUpdate == "function" &&
                  f.componentWillUpdate(l, $, g),
                typeof f.UNSAFE_componentWillUpdate == "function" &&
                  f.UNSAFE_componentWillUpdate(l, $, g)),
              typeof f.componentDidUpdate == "function" && (t.flags |= 4),
              typeof f.getSnapshotBeforeUpdate == "function" &&
                (t.flags |= 1024))
            : (typeof f.componentDidUpdate != "function" ||
                (C === e.memoizedProps && _ === e.memoizedState) ||
                (t.flags |= 4),
              typeof f.getSnapshotBeforeUpdate != "function" ||
                (C === e.memoizedProps && _ === e.memoizedState) ||
                (t.flags |= 1024),
              (t.memoizedProps = l),
              (t.memoizedState = $)),
          (f.props = l),
          (f.state = $),
          (f.context = g),
          (l = R))
        : (typeof f.componentDidUpdate != "function" ||
            (C === e.memoizedProps && _ === e.memoizedState) ||
            (t.flags |= 4),
          typeof f.getSnapshotBeforeUpdate != "function" ||
            (C === e.memoizedProps && _ === e.memoizedState) ||
            (t.flags |= 1024),
          (l = !1));
    }
    return Wi(e, t, n, l, u, o);
  }
  function Wi(e, t, n, l, o, u) {
    c2(e, t);
    var f = (t.flags & 128) !== 0;
    if (!l && !f) return (o && xo(t, n, !1), Bt(e, t, u));
    ((l = t.stateNode), (eu.current = t));
    var C =
      f && typeof n.getDerivedStateFromError != "function" ? null : l.render();
    return (
      (t.flags |= 1),
      e !== null && f
        ? ((t.child = Gn(t, e.child, null, u)), (t.child = Gn(t, null, C, u)))
        : We(e, t, C, u),
      (t.memoizedState = l.state),
      o && xo(t, n, !0),
      t.child
    );
  }
  function f2(e) {
    var t = e.stateNode;
    (t.pendingContext
      ? ho(e, t.pendingContext, t.pendingContext !== t.context)
      : t.context && ho(e, t.context, !1),
      Ri(e, t.containerInfo));
  }
  function m2(e, t, n, l, o) {
    return ($n(), yi(o), (t.flags |= 256), We(e, t, n, l), t.child);
  }
  var $i = { dehydrated: null, treeContext: null, retryLane: 0 };
  function Gi(e) {
    return { baseLanes: e, cachePool: null, transitions: null };
  }
  function h2(e, t, n) {
    var l = t.pendingProps,
      o = ye.current,
      u = !1,
      f = (t.flags & 128) !== 0,
      C;
    if (
      ((C = f) ||
        (C = e !== null && e.memoizedState === null ? !1 : (o & 2) !== 0),
      C
        ? ((u = !0), (t.flags &= -129))
        : (e === null || e.memoizedState !== null) && (o |= 1),
      pe(ye, o & 1),
      e === null)
    )
      return (
        wi(t),
        (e = t.memoizedState),
        e !== null && ((e = e.dehydrated), e !== null)
          ? ((t.mode & 1) === 0
              ? (t.lanes = 1)
              : e.data === "$!"
                ? (t.lanes = 8)
                : (t.lanes = 1073741824),
            null)
          : ((f = l.children),
            (e = l.fallback),
            u
              ? ((l = t.mode),
                (u = t.child),
                (f = { mode: "hidden", children: f }),
                (l & 1) === 0 && u !== null
                  ? ((u.childLanes = 0), (u.pendingProps = f))
                  : (u = el(f, l, 0, null)),
                (e = Ln(e, l, n, null)),
                (u.return = t),
                (e.return = t),
                (u.sibling = e),
                (t.child = u),
                (t.child.memoizedState = Gi(n)),
                (t.memoizedState = $i),
                e)
              : Qi(t, f))
      );
    if (((o = e.memoizedState), o !== null && ((C = o.dehydrated), C !== null)))
      return tu(e, t, f, l, C, o, n);
    if (u) {
      ((u = l.fallback), (f = t.mode), (o = e.child), (C = o.sibling));
      var g = { mode: "hidden", children: l.children };
      return (
        (f & 1) === 0 && t.child !== o
          ? ((l = t.child),
            (l.childLanes = 0),
            (l.pendingProps = g),
            (t.deletions = null))
          : ((l = on(o, g)), (l.subtreeFlags = o.subtreeFlags & 14680064)),
        C !== null ? (u = on(C, u)) : ((u = Ln(u, f, n, null)), (u.flags |= 2)),
        (u.return = t),
        (l.return = t),
        (l.sibling = u),
        (t.child = l),
        (l = u),
        (u = t.child),
        (f = e.child.memoizedState),
        (f =
          f === null
            ? Gi(n)
            : {
                baseLanes: f.baseLanes | n,
                cachePool: null,
                transitions: f.transitions,
              }),
        (u.memoizedState = f),
        (u.childLanes = e.childLanes & ~n),
        (t.memoizedState = $i),
        l
      );
    }
    return (
      (u = e.child),
      (e = u.sibling),
      (l = on(u, { mode: "visible", children: l.children })),
      (t.mode & 1) === 0 && (l.lanes = n),
      (l.return = t),
      (l.sibling = null),
      e !== null &&
        ((n = t.deletions),
        n === null ? ((t.deletions = [e]), (t.flags |= 16)) : n.push(e)),
      (t.child = l),
      (t.memoizedState = null),
      l
    );
  }
  function Qi(e, t) {
    return (
      (t = el({ mode: "visible", children: t }, e.mode, 0, null)),
      (t.return = e),
      (e.child = t)
    );
  }
  function V1(e, t, n, l) {
    return (
      l !== null && yi(l),
      Gn(t, e.child, null, n),
      (e = Qi(t, t.pendingProps.children)),
      (e.flags |= 2),
      (t.memoizedState = null),
      e
    );
  }
  function tu(e, t, n, l, o, u, f) {
    if (n)
      return t.flags & 256
        ? ((t.flags &= -257), (l = zi(Error(a(422)))), V1(e, t, f, l))
        : t.memoizedState !== null
          ? ((t.child = e.child), (t.flags |= 128), null)
          : ((u = l.fallback),
            (o = t.mode),
            (l = el({ mode: "visible", children: l.children }, o, 0, null)),
            (u = Ln(u, o, f, null)),
            (u.flags |= 2),
            (l.return = t),
            (u.return = t),
            (l.sibling = u),
            (t.child = l),
            (t.mode & 1) !== 0 && Gn(t, e.child, null, f),
            (t.child.memoizedState = Gi(f)),
            (t.memoizedState = $i),
            u);
    if ((t.mode & 1) === 0) return V1(e, t, f, null);
    if (o.data === "$!") {
      if (((l = o.nextSibling && o.nextSibling.dataset), l)) var C = l.dgst;
      return (
        (l = C),
        (u = Error(a(419))),
        (l = zi(u, l, void 0)),
        V1(e, t, f, l)
      );
    }
    if (((C = (f & e.childLanes) !== 0), Ke || C)) {
      if (((l = Fe), l !== null)) {
        switch (f & -f) {
          case 4:
            o = 2;
            break;
          case 16:
            o = 8;
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
            o = 32;
            break;
          case 536870912:
            o = 268435456;
            break;
          default:
            o = 0;
        }
        ((o = (o & (l.suspendedLanes | f)) !== 0 ? 0 : o),
          o !== 0 &&
            o !== u.retryLane &&
            ((u.retryLane = o), Tt(e, o), wt(l, e, o, -1)));
      }
      return (c0(), (l = zi(Error(a(421)))), V1(e, t, f, l));
    }
    return o.data === "$?"
      ? ((t.flags |= 128),
        (t.child = e.child),
        (t = hu.bind(null, e)),
        (o._reactRetry = t),
        null)
      : ((e = u.treeContext),
        (lt = Kt(o.nextSibling)),
        (rt = t),
        (we = !0),
        (xt = null),
        e !== null &&
          ((at[ut++] = It),
          (at[ut++] = Dt),
          (at[ut++] = pn),
          (It = e.id),
          (Dt = e.overflow),
          (pn = t)),
        (t = Qi(t, l.children)),
        (t.flags |= 4096),
        t);
  }
  function p2(e, t, n) {
    e.lanes |= t;
    var l = e.alternate;
    (l !== null && (l.lanes |= t), Ei(e.return, t, n));
  }
  function Ki(e, t, n, l, o) {
    var u = e.memoizedState;
    u === null
      ? (e.memoizedState = {
          isBackwards: t,
          rendering: null,
          renderingStartTime: 0,
          last: l,
          tail: n,
          tailMode: o,
        })
      : ((u.isBackwards = t),
        (u.rendering = null),
        (u.renderingStartTime = 0),
        (u.last = l),
        (u.tail = n),
        (u.tailMode = o));
  }
  function x2(e, t, n) {
    var l = t.pendingProps,
      o = l.revealOrder,
      u = l.tail;
    if ((We(e, t, l.children, n), (l = ye.current), (l & 2) !== 0))
      ((l = (l & 1) | 2), (t.flags |= 128));
    else {
      if (e !== null && (e.flags & 128) !== 0)
        e: for (e = t.child; e !== null; ) {
          if (e.tag === 13) e.memoizedState !== null && p2(e, n, t);
          else if (e.tag === 19) p2(e, n, t);
          else if (e.child !== null) {
            ((e.child.return = e), (e = e.child));
            continue;
          }
          if (e === t) break e;
          for (; e.sibling === null; ) {
            if (e.return === null || e.return === t) break e;
            e = e.return;
          }
          ((e.sibling.return = e.return), (e = e.sibling));
        }
      l &= 1;
    }
    if ((pe(ye, l), (t.mode & 1) === 0)) t.memoizedState = null;
    else
      switch (o) {
        case "forwards":
          for (n = t.child, o = null; n !== null; )
            ((e = n.alternate),
              e !== null && F1(e) === null && (o = n),
              (n = n.sibling));
          ((n = o),
            n === null
              ? ((o = t.child), (t.child = null))
              : ((o = n.sibling), (n.sibling = null)),
            Ki(t, !1, o, n, u));
          break;
        case "backwards":
          for (n = null, o = t.child, t.child = null; o !== null; ) {
            if (((e = o.alternate), e !== null && F1(e) === null)) {
              t.child = o;
              break;
            }
            ((e = o.sibling), (o.sibling = n), (n = o), (o = e));
          }
          Ki(t, !0, n, null, u);
          break;
        case "together":
          Ki(t, !1, null, null, void 0);
          break;
        default:
          t.memoizedState = null;
      }
    return t.child;
  }
  function z1(e, t) {
    (t.mode & 1) === 0 &&
      e !== null &&
      ((e.alternate = null), (t.alternate = null), (t.flags |= 2));
  }
  function Bt(e, t, n) {
    if (
      (e !== null && (t.dependencies = e.dependencies),
      (wn |= t.lanes),
      (n & t.childLanes) === 0)
    )
      return null;
    if (e !== null && t.child !== e.child) throw Error(a(153));
    if (t.child !== null) {
      for (
        e = t.child, n = on(e, e.pendingProps), t.child = n, n.return = t;
        e.sibling !== null;

      )
        ((e = e.sibling),
          (n = n.sibling = on(e, e.pendingProps)),
          (n.return = t));
      n.sibling = null;
    }
    return t.child;
  }
  function nu(e, t, n) {
    switch (t.tag) {
      case 3:
        (f2(t), $n());
        break;
      case 5:
        bo(t);
        break;
      case 1:
        Qe(t.type) && L1(t);
        break;
      case 4:
        Ri(t, t.stateNode.containerInfo);
        break;
      case 10:
        var l = t.type._context,
          o = t.memoizedProps.value;
        (pe(b1, l._currentValue), (l._currentValue = o));
        break;
      case 13:
        if (((l = t.memoizedState), l !== null))
          return l.dehydrated !== null
            ? (pe(ye, ye.current & 1), (t.flags |= 128), null)
            : (n & t.child.childLanes) !== 0
              ? h2(e, t, n)
              : (pe(ye, ye.current & 1),
                (e = Bt(e, t, n)),
                e !== null ? e.sibling : null);
        pe(ye, ye.current & 1);
        break;
      case 19:
        if (((l = (n & t.childLanes) !== 0), (e.flags & 128) !== 0)) {
          if (l) return x2(e, t, n);
          t.flags |= 128;
        }
        if (
          ((o = t.memoizedState),
          o !== null &&
            ((o.rendering = null), (o.tail = null), (o.lastEffect = null)),
          pe(ye, ye.current),
          l)
        )
          break;
        return null;
      case 22:
      case 23:
        return ((t.lanes = 0), u2(e, t, n));
    }
    return Bt(e, t, n);
  }
  var C2, Yi, v2, g2;
  ((C2 = function (e, t) {
    for (var n = t.child; n !== null; ) {
      if (n.tag === 5 || n.tag === 6) e.appendChild(n.stateNode);
      else if (n.tag !== 4 && n.child !== null) {
        ((n.child.return = n), (n = n.child));
        continue;
      }
      if (n === t) break;
      for (; n.sibling === null; ) {
        if (n.return === null || n.return === t) return;
        n = n.return;
      }
      ((n.sibling.return = n.return), (n = n.sibling));
    }
  }),
    (Yi = function () {}),
    (v2 = function (e, t, n, l) {
      var o = e.memoizedProps;
      if (o !== l) {
        ((e = t.stateNode), vn(Mt.current));
        var u = null;
        switch (n) {
          case "input":
            ((o = El(e, o)), (l = El(e, l)), (u = []));
            break;
          case "select":
            ((o = W({}, o, { value: void 0 })),
              (l = W({}, l, { value: void 0 })),
              (u = []));
            break;
          case "textarea":
            ((o = Rl(e, o)), (l = Rl(e, l)), (u = []));
            break;
          default:
            typeof o.onClick != "function" &&
              typeof l.onClick == "function" &&
              (e.onclick = y1);
        }
        bl(n, l);
        var f;
        n = null;
        for (R in o)
          if (!l.hasOwnProperty(R) && o.hasOwnProperty(R) && o[R] != null)
            if (R === "style") {
              var C = o[R];
              for (f in C) C.hasOwnProperty(f) && (n || (n = {}), (n[f] = ""));
            } else
              R !== "dangerouslySetInnerHTML" &&
                R !== "children" &&
                R !== "suppressContentEditableWarning" &&
                R !== "suppressHydrationWarning" &&
                R !== "autoFocus" &&
                (d.hasOwnProperty(R)
                  ? u || (u = [])
                  : (u = u || []).push(R, null));
        for (R in l) {
          var g = l[R];
          if (
            ((C = o != null ? o[R] : void 0),
            l.hasOwnProperty(R) && g !== C && (g != null || C != null))
          )
            if (R === "style")
              if (C) {
                for (f in C)
                  !C.hasOwnProperty(f) ||
                    (g && g.hasOwnProperty(f)) ||
                    (n || (n = {}), (n[f] = ""));
                for (f in g)
                  g.hasOwnProperty(f) &&
                    C[f] !== g[f] &&
                    (n || (n = {}), (n[f] = g[f]));
              } else (n || (u || (u = []), u.push(R, n)), (n = g));
            else
              R === "dangerouslySetInnerHTML"
                ? ((g = g ? g.__html : void 0),
                  (C = C ? C.__html : void 0),
                  g != null && C !== g && (u = u || []).push(R, g))
                : R === "children"
                  ? (typeof g != "string" && typeof g != "number") ||
                    (u = u || []).push(R, "" + g)
                  : R !== "suppressContentEditableWarning" &&
                    R !== "suppressHydrationWarning" &&
                    (d.hasOwnProperty(R)
                      ? (g != null && R === "onScroll" && Ce("scroll", e),
                        u || C === g || (u = []))
                      : (u = u || []).push(R, g));
        }
        n && (u = u || []).push("style", n);
        var R = u;
        (t.updateQueue = R) && (t.flags |= 4);
      }
    }),
    (g2 = function (e, t, n, l) {
      n !== l && (t.flags |= 4);
    }));
  function Vr(e, t) {
    if (!we)
      switch (e.tailMode) {
        case "hidden":
          t = e.tail;
          for (var n = null; t !== null; )
            (t.alternate !== null && (n = t), (t = t.sibling));
          n === null ? (e.tail = null) : (n.sibling = null);
          break;
        case "collapsed":
          n = e.tail;
          for (var l = null; n !== null; )
            (n.alternate !== null && (l = n), (n = n.sibling));
          l === null
            ? t || e.tail === null
              ? (e.tail = null)
              : (e.tail.sibling = null)
            : (l.sibling = null);
      }
  }
  function ze(e) {
    var t = e.alternate !== null && e.alternate.child === e.child,
      n = 0,
      l = 0;
    if (t)
      for (var o = e.child; o !== null; )
        ((n |= o.lanes | o.childLanes),
          (l |= o.subtreeFlags & 14680064),
          (l |= o.flags & 14680064),
          (o.return = e),
          (o = o.sibling));
    else
      for (o = e.child; o !== null; )
        ((n |= o.lanes | o.childLanes),
          (l |= o.subtreeFlags),
          (l |= o.flags),
          (o.return = e),
          (o = o.sibling));
    return ((e.subtreeFlags |= l), (e.childLanes = n), t);
  }
  function ru(e, t, n) {
    var l = t.pendingProps;
    switch ((vi(t), t.tag)) {
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
        return (ze(t), null);
      case 1:
        return (Qe(t.type) && N1(), ze(t), null);
      case 3:
        return (
          (l = t.stateNode),
          Yn(),
          ve(Ge),
          ve(He),
          Pi(),
          l.pendingContext &&
            ((l.context = l.pendingContext), (l.pendingContext = null)),
          (e === null || e.child === null) &&
            (R1(t)
              ? (t.flags |= 4)
              : e === null ||
                (e.memoizedState.isDehydrated && (t.flags & 256) === 0) ||
                ((t.flags |= 1024), xt !== null && (o0(xt), (xt = null)))),
          Yi(e, t),
          ze(t),
          null
        );
      case 5:
        Mi(t);
        var o = vn(Dr.current);
        if (((n = t.type), e !== null && t.stateNode != null))
          (v2(e, t, n, l, o),
            e.ref !== t.ref && ((t.flags |= 512), (t.flags |= 2097152)));
        else {
          if (!l) {
            if (t.stateNode === null) throw Error(a(166));
            return (ze(t), null);
          }
          if (((e = vn(Mt.current)), R1(t))) {
            ((l = t.stateNode), (n = t.type));
            var u = t.memoizedProps;
            switch (((l[Rt] = t), (l[Pr] = u), (e = (t.mode & 1) !== 0), n)) {
              case "dialog":
                (Ce("cancel", l), Ce("close", l));
                break;
              case "iframe":
              case "object":
              case "embed":
                Ce("load", l);
                break;
              case "video":
              case "audio":
                for (o = 0; o < Rr.length; o++) Ce(Rr[o], l);
                break;
              case "source":
                Ce("error", l);
                break;
              case "img":
              case "image":
              case "link":
                (Ce("error", l), Ce("load", l));
                break;
              case "details":
                Ce("toggle", l);
                break;
              case "input":
                (J0(l, u), Ce("invalid", l));
                break;
              case "select":
                ((l._wrapperState = { wasMultiple: !!u.multiple }),
                  Ce("invalid", l));
                break;
              case "textarea":
                (ts(l, u), Ce("invalid", l));
            }
            (bl(n, u), (o = null));
            for (var f in u)
              if (u.hasOwnProperty(f)) {
                var C = u[f];
                f === "children"
                  ? typeof C == "string"
                    ? l.textContent !== C &&
                      (u.suppressHydrationWarning !== !0 &&
                        w1(l.textContent, C, e),
                      (o = ["children", C]))
                    : typeof C == "number" &&
                      l.textContent !== "" + C &&
                      (u.suppressHydrationWarning !== !0 &&
                        w1(l.textContent, C, e),
                      (o = ["children", "" + C]))
                  : d.hasOwnProperty(f) &&
                    C != null &&
                    f === "onScroll" &&
                    Ce("scroll", l);
              }
            switch (n) {
              case "input":
                (Xr(l), es(l, u, !0));
                break;
              case "textarea":
                (Xr(l), rs(l));
                break;
              case "select":
              case "option":
                break;
              default:
                typeof u.onClick == "function" && (l.onclick = y1);
            }
            ((l = o), (t.updateQueue = l), l !== null && (t.flags |= 4));
          } else {
            ((f = o.nodeType === 9 ? o : o.ownerDocument),
              e === "http://www.w3.org/1999/xhtml" && (e = ls(n)),
              e === "http://www.w3.org/1999/xhtml"
                ? n === "script"
                  ? ((e = f.createElement("div")),
                    (e.innerHTML = "<script><\/script>"),
                    (e = e.removeChild(e.firstChild)))
                  : typeof l.is == "string"
                    ? (e = f.createElement(n, { is: l.is }))
                    : ((e = f.createElement(n)),
                      n === "select" &&
                        ((f = e),
                        l.multiple
                          ? (f.multiple = !0)
                          : l.size && (f.size = l.size)))
                : (e = f.createElementNS(e, n)),
              (e[Rt] = t),
              (e[Pr] = l),
              C2(e, t, !1, !1),
              (t.stateNode = e));
            e: {
              switch (((f = Pl(n, l)), n)) {
                case "dialog":
                  (Ce("cancel", e), Ce("close", e), (o = l));
                  break;
                case "iframe":
                case "object":
                case "embed":
                  (Ce("load", e), (o = l));
                  break;
                case "video":
                case "audio":
                  for (o = 0; o < Rr.length; o++) Ce(Rr[o], e);
                  o = l;
                  break;
                case "source":
                  (Ce("error", e), (o = l));
                  break;
                case "img":
                case "image":
                case "link":
                  (Ce("error", e), Ce("load", e), (o = l));
                  break;
                case "details":
                  (Ce("toggle", e), (o = l));
                  break;
                case "input":
                  (J0(e, l), (o = El(e, l)), Ce("invalid", e));
                  break;
                case "option":
                  o = l;
                  break;
                case "select":
                  ((e._wrapperState = { wasMultiple: !!l.multiple }),
                    (o = W({}, l, { value: void 0 })),
                    Ce("invalid", e));
                  break;
                case "textarea":
                  (ts(e, l), (o = Rl(e, l)), Ce("invalid", e));
                  break;
                default:
                  o = l;
              }
              (bl(n, o), (C = o));
              for (u in C)
                if (C.hasOwnProperty(u)) {
                  var g = C[u];
                  u === "style"
                    ? os(e, g)
                    : u === "dangerouslySetInnerHTML"
                      ? ((g = g ? g.__html : void 0), g != null && is(e, g))
                      : u === "children"
                        ? typeof g == "string"
                          ? (n !== "textarea" || g !== "") && ur(e, g)
                          : typeof g == "number" && ur(e, "" + g)
                        : u !== "suppressContentEditableWarning" &&
                          u !== "suppressHydrationWarning" &&
                          u !== "autoFocus" &&
                          (d.hasOwnProperty(u)
                            ? g != null && u === "onScroll" && Ce("scroll", e)
                            : g != null && V(e, u, g, f));
                }
              switch (n) {
                case "input":
                  (Xr(e), es(e, l, !1));
                  break;
                case "textarea":
                  (Xr(e), rs(e));
                  break;
                case "option":
                  l.value != null && e.setAttribute("value", "" + fe(l.value));
                  break;
                case "select":
                  ((e.multiple = !!l.multiple),
                    (u = l.value),
                    u != null
                      ? Pn(e, !!l.multiple, u, !1)
                      : l.defaultValue != null &&
                        Pn(e, !!l.multiple, l.defaultValue, !0));
                  break;
                default:
                  typeof o.onClick == "function" && (e.onclick = y1);
              }
              switch (n) {
                case "button":
                case "input":
                case "select":
                case "textarea":
                  l = !!l.autoFocus;
                  break e;
                case "img":
                  l = !0;
                  break e;
                default:
                  l = !1;
              }
            }
            l && (t.flags |= 4);
          }
          t.ref !== null && ((t.flags |= 512), (t.flags |= 2097152));
        }
        return (ze(t), null);
      case 6:
        if (e && t.stateNode != null) g2(e, t, e.memoizedProps, l);
        else {
          if (typeof l != "string" && t.stateNode === null) throw Error(a(166));
          if (((n = vn(Dr.current)), vn(Mt.current), R1(t))) {
            if (
              ((l = t.stateNode),
              (n = t.memoizedProps),
              (l[Rt] = t),
              (u = l.nodeValue !== n) && ((e = rt), e !== null))
            )
              switch (e.tag) {
                case 3:
                  w1(l.nodeValue, n, (e.mode & 1) !== 0);
                  break;
                case 5:
                  e.memoizedProps.suppressHydrationWarning !== !0 &&
                    w1(l.nodeValue, n, (e.mode & 1) !== 0);
              }
            u && (t.flags |= 4);
          } else
            ((l = (n.nodeType === 9 ? n : n.ownerDocument).createTextNode(l)),
              (l[Rt] = t),
              (t.stateNode = l));
        }
        return (ze(t), null);
      case 13:
        if (
          (ve(ye),
          (l = t.memoizedState),
          e === null ||
            (e.memoizedState !== null && e.memoizedState.dehydrated !== null))
        ) {
          if (we && lt !== null && (t.mode & 1) !== 0 && (t.flags & 128) === 0)
            (jo(), $n(), (t.flags |= 98560), (u = !1));
          else if (((u = R1(t)), l !== null && l.dehydrated !== null)) {
            if (e === null) {
              if (!u) throw Error(a(318));
              if (
                ((u = t.memoizedState),
                (u = u !== null ? u.dehydrated : null),
                !u)
              )
                throw Error(a(317));
              u[Rt] = t;
            } else
              ($n(),
                (t.flags & 128) === 0 && (t.memoizedState = null),
                (t.flags |= 4));
            (ze(t), (u = !1));
          } else (xt !== null && (o0(xt), (xt = null)), (u = !0));
          if (!u) return t.flags & 65536 ? t : null;
        }
        return (t.flags & 128) !== 0
          ? ((t.lanes = n), t)
          : ((l = l !== null),
            l !== (e !== null && e.memoizedState !== null) &&
              l &&
              ((t.child.flags |= 8192),
              (t.mode & 1) !== 0 &&
                (e === null || (ye.current & 1) !== 0
                  ? Me === 0 && (Me = 3)
                  : c0())),
            t.updateQueue !== null && (t.flags |= 4),
            ze(t),
            null);
      case 4:
        return (
          Yn(),
          Yi(e, t),
          e === null && Mr(t.stateNode.containerInfo),
          ze(t),
          null
        );
      case 10:
        return (Li(t.type._context), ze(t), null);
      case 17:
        return (Qe(t.type) && N1(), ze(t), null);
      case 19:
        if ((ve(ye), (u = t.memoizedState), u === null)) return (ze(t), null);
        if (((l = (t.flags & 128) !== 0), (f = u.rendering), f === null))
          if (l) Vr(u, !1);
          else {
            if (Me !== 0 || (e !== null && (e.flags & 128) !== 0))
              for (e = t.child; e !== null; ) {
                if (((f = F1(e)), f !== null)) {
                  for (
                    t.flags |= 128,
                      Vr(u, !1),
                      l = f.updateQueue,
                      l !== null && ((t.updateQueue = l), (t.flags |= 4)),
                      t.subtreeFlags = 0,
                      l = n,
                      n = t.child;
                    n !== null;

                  )
                    ((u = n),
                      (e = l),
                      (u.flags &= 14680066),
                      (f = u.alternate),
                      f === null
                        ? ((u.childLanes = 0),
                          (u.lanes = e),
                          (u.child = null),
                          (u.subtreeFlags = 0),
                          (u.memoizedProps = null),
                          (u.memoizedState = null),
                          (u.updateQueue = null),
                          (u.dependencies = null),
                          (u.stateNode = null))
                        : ((u.childLanes = f.childLanes),
                          (u.lanes = f.lanes),
                          (u.child = f.child),
                          (u.subtreeFlags = 0),
                          (u.deletions = null),
                          (u.memoizedProps = f.memoizedProps),
                          (u.memoizedState = f.memoizedState),
                          (u.updateQueue = f.updateQueue),
                          (u.type = f.type),
                          (e = f.dependencies),
                          (u.dependencies =
                            e === null
                              ? null
                              : {
                                  lanes: e.lanes,
                                  firstContext: e.firstContext,
                                })),
                      (n = n.sibling));
                  return (pe(ye, (ye.current & 1) | 2), t.child);
                }
                e = e.sibling;
              }
            u.tail !== null &&
              Ee() > er &&
              ((t.flags |= 128), (l = !0), Vr(u, !1), (t.lanes = 4194304));
          }
        else {
          if (!l)
            if (((e = F1(f)), e !== null)) {
              if (
                ((t.flags |= 128),
                (l = !0),
                (n = e.updateQueue),
                n !== null && ((t.updateQueue = n), (t.flags |= 4)),
                Vr(u, !0),
                u.tail === null &&
                  u.tailMode === "hidden" &&
                  !f.alternate &&
                  !we)
              )
                return (ze(t), null);
            } else
              2 * Ee() - u.renderingStartTime > er &&
                n !== 1073741824 &&
                ((t.flags |= 128), (l = !0), Vr(u, !1), (t.lanes = 4194304));
          u.isBackwards
            ? ((f.sibling = t.child), (t.child = f))
            : ((n = u.last),
              n !== null ? (n.sibling = f) : (t.child = f),
              (u.last = f));
        }
        return u.tail !== null
          ? ((t = u.tail),
            (u.rendering = t),
            (u.tail = t.sibling),
            (u.renderingStartTime = Ee()),
            (t.sibling = null),
            (n = ye.current),
            pe(ye, l ? (n & 1) | 2 : n & 1),
            t)
          : (ze(t), null);
      case 22:
      case 23:
        return (
          u0(),
          (l = t.memoizedState !== null),
          e !== null && (e.memoizedState !== null) !== l && (t.flags |= 8192),
          l && (t.mode & 1) !== 0
            ? (it & 1073741824) !== 0 &&
              (ze(t), t.subtreeFlags & 6 && (t.flags |= 8192))
            : ze(t),
          null
        );
      case 24:
        return null;
      case 25:
        return null;
    }
    throw Error(a(156, t.tag));
  }
  function lu(e, t) {
    switch ((vi(t), t.tag)) {
      case 1:
        return (
          Qe(t.type) && N1(),
          (e = t.flags),
          e & 65536 ? ((t.flags = (e & -65537) | 128), t) : null
        );
      case 3:
        return (
          Yn(),
          ve(Ge),
          ve(He),
          Pi(),
          (e = t.flags),
          (e & 65536) !== 0 && (e & 128) === 0
            ? ((t.flags = (e & -65537) | 128), t)
            : null
        );
      case 5:
        return (Mi(t), null);
      case 13:
        if (
          (ve(ye), (e = t.memoizedState), e !== null && e.dehydrated !== null)
        ) {
          if (t.alternate === null) throw Error(a(340));
          $n();
        }
        return (
          (e = t.flags),
          e & 65536 ? ((t.flags = (e & -65537) | 128), t) : null
        );
      case 19:
        return (ve(ye), null);
      case 4:
        return (Yn(), null);
      case 10:
        return (Li(t.type._context), null);
      case 22:
      case 23:
        return (u0(), null);
      case 24:
        return null;
      default:
        return null;
    }
  }
  var U1 = !1,
    Ue = !1,
    iu = typeof WeakSet == "function" ? WeakSet : Set,
    U = null;
  function Jn(e, t) {
    var n = e.ref;
    if (n !== null)
      if (typeof n == "function")
        try {
          n(null);
        } catch (l) {
          Ne(e, t, l);
        }
      else n.current = null;
  }
  function Xi(e, t, n) {
    try {
      n();
    } catch (l) {
      Ne(e, t, l);
    }
  }
  var w2 = !1;
  function su(e, t) {
    if (((ui = u1), (e = Xs()), ti(e))) {
      if ("selectionStart" in e)
        var n = { start: e.selectionStart, end: e.selectionEnd };
      else
        e: {
          n = ((n = e.ownerDocument) && n.defaultView) || window;
          var l = n.getSelection && n.getSelection();
          if (l && l.rangeCount !== 0) {
            n = l.anchorNode;
            var o = l.anchorOffset,
              u = l.focusNode;
            l = l.focusOffset;
            try {
              (n.nodeType, u.nodeType);
            } catch {
              n = null;
              break e;
            }
            var f = 0,
              C = -1,
              g = -1,
              R = 0,
              D = 0,
              A = e,
              _ = null;
            t: for (;;) {
              for (
                var z;
                A !== n || (o !== 0 && A.nodeType !== 3) || (C = f + o),
                  A !== u || (l !== 0 && A.nodeType !== 3) || (g = f + l),
                  A.nodeType === 3 && (f += A.nodeValue.length),
                  (z = A.firstChild) !== null;

              )
                ((_ = A), (A = z));
              for (;;) {
                if (A === e) break t;
                if (
                  (_ === n && ++R === o && (C = f),
                  _ === u && ++D === l && (g = f),
                  (z = A.nextSibling) !== null)
                )
                  break;
                ((A = _), (_ = A.parentNode));
              }
              A = z;
            }
            n = C === -1 || g === -1 ? null : { start: C, end: g };
          } else n = null;
        }
      n = n || { start: 0, end: 0 };
    } else n = null;
    for (
      ci = { focusedElem: e, selectionRange: n }, u1 = !1, U = t;
      U !== null;

    )
      if (((t = U), (e = t.child), (t.subtreeFlags & 1028) !== 0 && e !== null))
        ((e.return = t), (U = e));
      else
        for (; U !== null; ) {
          t = U;
          try {
            var $ = t.alternate;
            if ((t.flags & 1024) !== 0)
              switch (t.tag) {
                case 0:
                case 11:
                case 15:
                  break;
                case 1:
                  if ($ !== null) {
                    var G = $.memoizedProps,
                      Se = $.memoizedState,
                      E = t.stateNode,
                      w = E.getSnapshotBeforeUpdate(
                        t.elementType === t.type ? G : Ct(t.type, G),
                        Se,
                      );
                    E.__reactInternalSnapshotBeforeUpdate = w;
                  }
                  break;
                case 3:
                  var S = t.stateNode.containerInfo;
                  S.nodeType === 1
                    ? (S.textContent = "")
                    : S.nodeType === 9 &&
                      S.documentElement &&
                      S.removeChild(S.documentElement);
                  break;
                case 5:
                case 6:
                case 4:
                case 17:
                  break;
                default:
                  throw Error(a(163));
              }
          } catch (B) {
            Ne(t, t.return, B);
          }
          if (((e = t.sibling), e !== null)) {
            ((e.return = t.return), (U = e));
            break;
          }
          U = t.return;
        }
    return (($ = w2), (w2 = !1), $);
  }
  function zr(e, t, n) {
    var l = t.updateQueue;
    if (((l = l !== null ? l.lastEffect : null), l !== null)) {
      var o = (l = l.next);
      do {
        if ((o.tag & e) === e) {
          var u = o.destroy;
          ((o.destroy = void 0), u !== void 0 && Xi(t, n, u));
        }
        o = o.next;
      } while (o !== l);
    }
  }
  function Z1(e, t) {
    if (
      ((t = t.updateQueue), (t = t !== null ? t.lastEffect : null), t !== null)
    ) {
      var n = (t = t.next);
      do {
        if ((n.tag & e) === e) {
          var l = n.create;
          n.destroy = l();
        }
        n = n.next;
      } while (n !== t);
    }
  }
  function Ji(e) {
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
  function y2(e) {
    var t = e.alternate;
    (t !== null && ((e.alternate = null), y2(t)),
      (e.child = null),
      (e.deletions = null),
      (e.sibling = null),
      e.tag === 5 &&
        ((t = e.stateNode),
        t !== null &&
          (delete t[Rt],
          delete t[Pr],
          delete t[hi],
          delete t[z3],
          delete t[U3])),
      (e.stateNode = null),
      (e.return = null),
      (e.dependencies = null),
      (e.memoizedProps = null),
      (e.memoizedState = null),
      (e.pendingProps = null),
      (e.stateNode = null),
      (e.updateQueue = null));
  }
  function j2(e) {
    return e.tag === 5 || e.tag === 3 || e.tag === 4;
  }
  function N2(e) {
    e: for (;;) {
      for (; e.sibling === null; ) {
        if (e.return === null || j2(e.return)) return null;
        e = e.return;
      }
      for (
        e.sibling.return = e.return, e = e.sibling;
        e.tag !== 5 && e.tag !== 6 && e.tag !== 18;

      ) {
        if (e.flags & 2 || e.child === null || e.tag === 4) continue e;
        ((e.child.return = e), (e = e.child));
      }
      if (!(e.flags & 2)) return e.stateNode;
    }
  }
  function qi(e, t, n) {
    var l = e.tag;
    if (l === 5 || l === 6)
      ((e = e.stateNode),
        t
          ? n.nodeType === 8
            ? n.parentNode.insertBefore(e, t)
            : n.insertBefore(e, t)
          : (n.nodeType === 8
              ? ((t = n.parentNode), t.insertBefore(e, n))
              : ((t = n), t.appendChild(e)),
            (n = n._reactRootContainer),
            n != null || t.onclick !== null || (t.onclick = y1)));
    else if (l !== 4 && ((e = e.child), e !== null))
      for (qi(e, t, n), e = e.sibling; e !== null; )
        (qi(e, t, n), (e = e.sibling));
  }
  function e0(e, t, n) {
    var l = e.tag;
    if (l === 5 || l === 6)
      ((e = e.stateNode), t ? n.insertBefore(e, t) : n.appendChild(e));
    else if (l !== 4 && ((e = e.child), e !== null))
      for (e0(e, t, n), e = e.sibling; e !== null; )
        (e0(e, t, n), (e = e.sibling));
  }
  var De = null,
    vt = !1;
  function tn(e, t, n) {
    for (n = n.child; n !== null; ) (L2(e, t, n), (n = n.sibling));
  }
  function L2(e, t, n) {
    if (kt && typeof kt.onCommitFiberUnmount == "function")
      try {
        kt.onCommitFiberUnmount(r1, n);
      } catch {}
    switch (n.tag) {
      case 5:
        Ue || Jn(n, t);
      case 6:
        var l = De,
          o = vt;
        ((De = null),
          tn(e, t, n),
          (De = l),
          (vt = o),
          De !== null &&
            (vt
              ? ((e = De),
                (n = n.stateNode),
                e.nodeType === 8
                  ? e.parentNode.removeChild(n)
                  : e.removeChild(n))
              : De.removeChild(n.stateNode)));
        break;
      case 18:
        De !== null &&
          (vt
            ? ((e = De),
              (n = n.stateNode),
              e.nodeType === 8
                ? mi(e.parentNode, n)
                : e.nodeType === 1 && mi(e, n),
              wr(e))
            : mi(De, n.stateNode));
        break;
      case 4:
        ((l = De),
          (o = vt),
          (De = n.stateNode.containerInfo),
          (vt = !0),
          tn(e, t, n),
          (De = l),
          (vt = o));
        break;
      case 0:
      case 11:
      case 14:
      case 15:
        if (
          !Ue &&
          ((l = n.updateQueue), l !== null && ((l = l.lastEffect), l !== null))
        ) {
          o = l = l.next;
          do {
            var u = o,
              f = u.destroy;
            ((u = u.tag),
              f !== void 0 && ((u & 2) !== 0 || (u & 4) !== 0) && Xi(n, t, f),
              (o = o.next));
          } while (o !== l);
        }
        tn(e, t, n);
        break;
      case 1:
        if (
          !Ue &&
          (Jn(n, t),
          (l = n.stateNode),
          typeof l.componentWillUnmount == "function")
        )
          try {
            ((l.props = n.memoizedProps),
              (l.state = n.memoizedState),
              l.componentWillUnmount());
          } catch (C) {
            Ne(n, t, C);
          }
        tn(e, t, n);
        break;
      case 21:
        tn(e, t, n);
        break;
      case 22:
        n.mode & 1
          ? ((Ue = (l = Ue) || n.memoizedState !== null), tn(e, t, n), (Ue = l))
          : tn(e, t, n);
        break;
      default:
        tn(e, t, n);
    }
  }
  function E2(e) {
    var t = e.updateQueue;
    if (t !== null) {
      e.updateQueue = null;
      var n = e.stateNode;
      (n === null && (n = e.stateNode = new iu()),
        t.forEach(function (l) {
          var o = pu.bind(null, e, l);
          n.has(l) || (n.add(l), l.then(o, o));
        }));
    }
  }
  function gt(e, t) {
    var n = t.deletions;
    if (n !== null)
      for (var l = 0; l < n.length; l++) {
        var o = n[l];
        try {
          var u = e,
            f = t,
            C = f;
          e: for (; C !== null; ) {
            switch (C.tag) {
              case 5:
                ((De = C.stateNode), (vt = !1));
                break e;
              case 3:
                ((De = C.stateNode.containerInfo), (vt = !0));
                break e;
              case 4:
                ((De = C.stateNode.containerInfo), (vt = !0));
                break e;
            }
            C = C.return;
          }
          if (De === null) throw Error(a(160));
          (L2(u, f, o), (De = null), (vt = !1));
          var g = o.alternate;
          (g !== null && (g.return = null), (o.return = null));
        } catch (R) {
          Ne(o, t, R);
        }
      }
    if (t.subtreeFlags & 12854)
      for (t = t.child; t !== null; ) (S2(t, e), (t = t.sibling));
  }
  function S2(e, t) {
    var n = e.alternate,
      l = e.flags;
    switch (e.tag) {
      case 0:
      case 11:
      case 14:
      case 15:
        if ((gt(t, e), Pt(e), l & 4)) {
          try {
            (zr(3, e, e.return), Z1(3, e));
          } catch (G) {
            Ne(e, e.return, G);
          }
          try {
            zr(5, e, e.return);
          } catch (G) {
            Ne(e, e.return, G);
          }
        }
        break;
      case 1:
        (gt(t, e), Pt(e), l & 512 && n !== null && Jn(n, n.return));
        break;
      case 5:
        if (
          (gt(t, e),
          Pt(e),
          l & 512 && n !== null && Jn(n, n.return),
          e.flags & 32)
        ) {
          var o = e.stateNode;
          try {
            ur(o, "");
          } catch (G) {
            Ne(e, e.return, G);
          }
        }
        if (l & 4 && ((o = e.stateNode), o != null)) {
          var u = e.memoizedProps,
            f = n !== null ? n.memoizedProps : u,
            C = e.type,
            g = e.updateQueue;
          if (((e.updateQueue = null), g !== null))
            try {
              (C === "input" &&
                u.type === "radio" &&
                u.name != null &&
                q0(o, u),
                Pl(C, f));
              var R = Pl(C, u);
              for (f = 0; f < g.length; f += 2) {
                var D = g[f],
                  A = g[f + 1];
                D === "style"
                  ? os(o, A)
                  : D === "dangerouslySetInnerHTML"
                    ? is(o, A)
                    : D === "children"
                      ? ur(o, A)
                      : V(o, D, A, R);
              }
              switch (C) {
                case "input":
                  Sl(o, u);
                  break;
                case "textarea":
                  ns(o, u);
                  break;
                case "select":
                  var _ = o._wrapperState.wasMultiple;
                  o._wrapperState.wasMultiple = !!u.multiple;
                  var z = u.value;
                  z != null
                    ? Pn(o, !!u.multiple, z, !1)
                    : _ !== !!u.multiple &&
                      (u.defaultValue != null
                        ? Pn(o, !!u.multiple, u.defaultValue, !0)
                        : Pn(o, !!u.multiple, u.multiple ? [] : "", !1));
              }
              o[Pr] = u;
            } catch (G) {
              Ne(e, e.return, G);
            }
        }
        break;
      case 6:
        if ((gt(t, e), Pt(e), l & 4)) {
          if (e.stateNode === null) throw Error(a(162));
          ((o = e.stateNode), (u = e.memoizedProps));
          try {
            o.nodeValue = u;
          } catch (G) {
            Ne(e, e.return, G);
          }
        }
        break;
      case 3:
        if (
          (gt(t, e), Pt(e), l & 4 && n !== null && n.memoizedState.isDehydrated)
        )
          try {
            wr(t.containerInfo);
          } catch (G) {
            Ne(e, e.return, G);
          }
        break;
      case 4:
        (gt(t, e), Pt(e));
        break;
      case 13:
        (gt(t, e),
          Pt(e),
          (o = e.child),
          o.flags & 8192 &&
            ((u = o.memoizedState !== null),
            (o.stateNode.isHidden = u),
            !u ||
              (o.alternate !== null && o.alternate.memoizedState !== null) ||
              (r0 = Ee())),
          l & 4 && E2(e));
        break;
      case 22:
        if (
          ((D = n !== null && n.memoizedState !== null),
          e.mode & 1 ? ((Ue = (R = Ue) || D), gt(t, e), (Ue = R)) : gt(t, e),
          Pt(e),
          l & 8192)
        ) {
          if (
            ((R = e.memoizedState !== null),
            (e.stateNode.isHidden = R) && !D && (e.mode & 1) !== 0)
          )
            for (U = e, D = e.child; D !== null; ) {
              for (A = U = D; U !== null; ) {
                switch (((_ = U), (z = _.child), _.tag)) {
                  case 0:
                  case 11:
                  case 14:
                  case 15:
                    zr(4, _, _.return);
                    break;
                  case 1:
                    Jn(_, _.return);
                    var $ = _.stateNode;
                    if (typeof $.componentWillUnmount == "function") {
                      ((l = _), (n = _.return));
                      try {
                        ((t = l),
                          ($.props = t.memoizedProps),
                          ($.state = t.memoizedState),
                          $.componentWillUnmount());
                      } catch (G) {
                        Ne(l, n, G);
                      }
                    }
                    break;
                  case 5:
                    Jn(_, _.return);
                    break;
                  case 22:
                    if (_.memoizedState !== null) {
                      M2(A);
                      continue;
                    }
                }
                z !== null ? ((z.return = _), (U = z)) : M2(A);
              }
              D = D.sibling;
            }
          e: for (D = null, A = e; ; ) {
            if (A.tag === 5) {
              if (D === null) {
                D = A;
                try {
                  ((o = A.stateNode),
                    R
                      ? ((u = o.style),
                        typeof u.setProperty == "function"
                          ? u.setProperty("display", "none", "important")
                          : (u.display = "none"))
                      : ((C = A.stateNode),
                        (g = A.memoizedProps.style),
                        (f =
                          g != null && g.hasOwnProperty("display")
                            ? g.display
                            : null),
                        (C.style.display = ss("display", f))));
                } catch (G) {
                  Ne(e, e.return, G);
                }
              }
            } else if (A.tag === 6) {
              if (D === null)
                try {
                  A.stateNode.nodeValue = R ? "" : A.memoizedProps;
                } catch (G) {
                  Ne(e, e.return, G);
                }
            } else if (
              ((A.tag !== 22 && A.tag !== 23) ||
                A.memoizedState === null ||
                A === e) &&
              A.child !== null
            ) {
              ((A.child.return = A), (A = A.child));
              continue;
            }
            if (A === e) break e;
            for (; A.sibling === null; ) {
              if (A.return === null || A.return === e) break e;
              (D === A && (D = null), (A = A.return));
            }
            (D === A && (D = null),
              (A.sibling.return = A.return),
              (A = A.sibling));
          }
        }
        break;
      case 19:
        (gt(t, e), Pt(e), l & 4 && E2(e));
        break;
      case 21:
        break;
      default:
        (gt(t, e), Pt(e));
    }
  }
  function Pt(e) {
    var t = e.flags;
    if (t & 2) {
      try {
        e: {
          for (var n = e.return; n !== null; ) {
            if (j2(n)) {
              var l = n;
              break e;
            }
            n = n.return;
          }
          throw Error(a(160));
        }
        switch (l.tag) {
          case 5:
            var o = l.stateNode;
            l.flags & 32 && (ur(o, ""), (l.flags &= -33));
            var u = N2(e);
            e0(e, u, o);
            break;
          case 3:
          case 4:
            var f = l.stateNode.containerInfo,
              C = N2(e);
            qi(e, C, f);
            break;
          default:
            throw Error(a(161));
        }
      } catch (g) {
        Ne(e, e.return, g);
      }
      e.flags &= -3;
    }
    t & 4096 && (e.flags &= -4097);
  }
  function ou(e, t, n) {
    ((U = e), k2(e));
  }
  function k2(e, t, n) {
    for (var l = (e.mode & 1) !== 0; U !== null; ) {
      var o = U,
        u = o.child;
      if (o.tag === 22 && l) {
        var f = o.memoizedState !== null || U1;
        if (!f) {
          var C = o.alternate,
            g = (C !== null && C.memoizedState !== null) || Ue;
          C = U1;
          var R = Ue;
          if (((U1 = f), (Ue = g) && !R))
            for (U = o; U !== null; )
              ((f = U),
                (g = f.child),
                f.tag === 22 && f.memoizedState !== null
                  ? b2(o)
                  : g !== null
                    ? ((g.return = f), (U = g))
                    : b2(o));
          for (; u !== null; ) ((U = u), k2(u), (u = u.sibling));
          ((U = o), (U1 = C), (Ue = R));
        }
        R2(e);
      } else
        (o.subtreeFlags & 8772) !== 0 && u !== null
          ? ((u.return = o), (U = u))
          : R2(e);
    }
  }
  function R2(e) {
    for (; U !== null; ) {
      var t = U;
      if ((t.flags & 8772) !== 0) {
        var n = t.alternate;
        try {
          if ((t.flags & 8772) !== 0)
            switch (t.tag) {
              case 0:
              case 11:
              case 15:
                Ue || Z1(5, t);
                break;
              case 1:
                var l = t.stateNode;
                if (t.flags & 4 && !Ue)
                  if (n === null) l.componentDidMount();
                  else {
                    var o =
                      t.elementType === t.type
                        ? n.memoizedProps
                        : Ct(t.type, n.memoizedProps);
                    l.componentDidUpdate(
                      o,
                      n.memoizedState,
                      l.__reactInternalSnapshotBeforeUpdate,
                    );
                  }
                var u = t.updateQueue;
                u !== null && Mo(t, u, l);
                break;
              case 3:
                var f = t.updateQueue;
                if (f !== null) {
                  if (((n = null), t.child !== null))
                    switch (t.child.tag) {
                      case 5:
                        n = t.child.stateNode;
                        break;
                      case 1:
                        n = t.child.stateNode;
                    }
                  Mo(t, f, n);
                }
                break;
              case 5:
                var C = t.stateNode;
                if (n === null && t.flags & 4) {
                  n = C;
                  var g = t.memoizedProps;
                  switch (t.type) {
                    case "button":
                    case "input":
                    case "select":
                    case "textarea":
                      g.autoFocus && n.focus();
                      break;
                    case "img":
                      g.src && (n.src = g.src);
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
                  var R = t.alternate;
                  if (R !== null) {
                    var D = R.memoizedState;
                    if (D !== null) {
                      var A = D.dehydrated;
                      A !== null && wr(A);
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
                throw Error(a(163));
            }
          Ue || (t.flags & 512 && Ji(t));
        } catch (_) {
          Ne(t, t.return, _);
        }
      }
      if (t === e) {
        U = null;
        break;
      }
      if (((n = t.sibling), n !== null)) {
        ((n.return = t.return), (U = n));
        break;
      }
      U = t.return;
    }
  }
  function M2(e) {
    for (; U !== null; ) {
      var t = U;
      if (t === e) {
        U = null;
        break;
      }
      var n = t.sibling;
      if (n !== null) {
        ((n.return = t.return), (U = n));
        break;
      }
      U = t.return;
    }
  }
  function b2(e) {
    for (; U !== null; ) {
      var t = U;
      try {
        switch (t.tag) {
          case 0:
          case 11:
          case 15:
            var n = t.return;
            try {
              Z1(4, t);
            } catch (g) {
              Ne(t, n, g);
            }
            break;
          case 1:
            var l = t.stateNode;
            if (typeof l.componentDidMount == "function") {
              var o = t.return;
              try {
                l.componentDidMount();
              } catch (g) {
                Ne(t, o, g);
              }
            }
            var u = t.return;
            try {
              Ji(t);
            } catch (g) {
              Ne(t, u, g);
            }
            break;
          case 5:
            var f = t.return;
            try {
              Ji(t);
            } catch (g) {
              Ne(t, f, g);
            }
        }
      } catch (g) {
        Ne(t, t.return, g);
      }
      if (t === e) {
        U = null;
        break;
      }
      var C = t.sibling;
      if (C !== null) {
        ((C.return = t.return), (U = C));
        break;
      }
      U = t.return;
    }
  }
  var au = Math.ceil,
    W1 = Z.ReactCurrentDispatcher,
    t0 = Z.ReactCurrentOwner,
    ft = Z.ReactCurrentBatchConfig,
    oe = 0,
    Fe = null,
    ke = null,
    Te = 0,
    it = 0,
    qn = Yt(0),
    Me = 0,
    Ur = null,
    wn = 0,
    $1 = 0,
    n0 = 0,
    Zr = null,
    Ye = null,
    r0 = 0,
    er = 1 / 0,
    Ht = null,
    G1 = !1,
    l0 = null,
    nn = null,
    Q1 = !1,
    rn = null,
    K1 = 0,
    Wr = 0,
    i0 = null,
    Y1 = -1,
    X1 = 0;
  function $e() {
    return (oe & 6) !== 0 ? Ee() : Y1 !== -1 ? Y1 : (Y1 = Ee());
  }
  function ln(e) {
    return (e.mode & 1) === 0
      ? 1
      : (oe & 2) !== 0 && Te !== 0
        ? Te & -Te
        : W3.transition !== null
          ? (X1 === 0 && (X1 = js()), X1)
          : ((e = me),
            e !== 0 ||
              ((e = window.event), (e = e === void 0 ? 16 : Ps(e.type))),
            e);
  }
  function wt(e, t, n, l) {
    if (50 < Wr) throw ((Wr = 0), (i0 = null), Error(a(185)));
    (pr(e, n, l),
      ((oe & 2) === 0 || e !== Fe) &&
        (e === Fe && ((oe & 2) === 0 && ($1 |= n), Me === 4 && sn(e, Te)),
        Xe(e, l),
        n === 1 &&
          oe === 0 &&
          (t.mode & 1) === 0 &&
          ((er = Ee() + 500), E1 && Jt())));
  }
  function Xe(e, t) {
    var n = e.callbackNode;
    W5(e, t);
    var l = s1(e, e === Fe ? Te : 0);
    if (l === 0)
      (n !== null && gs(n), (e.callbackNode = null), (e.callbackPriority = 0));
    else if (((t = l & -l), e.callbackPriority !== t)) {
      if ((n != null && gs(n), t === 1))
        (e.tag === 0 ? Z3(O2.bind(null, e)) : Co(O2.bind(null, e)),
          H3(function () {
            (oe & 6) === 0 && Jt();
          }),
          (n = null));
      else {
        switch (Ns(l)) {
          case 1:
            n = Al;
            break;
          case 4:
            n = ws;
            break;
          case 16:
            n = n1;
            break;
          case 536870912:
            n = ys;
            break;
          default:
            n = n1;
        }
        n = H2(n, P2.bind(null, e));
      }
      ((e.callbackPriority = t), (e.callbackNode = n));
    }
  }
  function P2(e, t) {
    if (((Y1 = -1), (X1 = 0), (oe & 6) !== 0)) throw Error(a(327));
    var n = e.callbackNode;
    if (tr() && e.callbackNode !== n) return null;
    var l = s1(e, e === Fe ? Te : 0);
    if (l === 0) return null;
    if ((l & 30) !== 0 || (l & e.expiredLanes) !== 0 || t) t = J1(e, l);
    else {
      t = l;
      var o = oe;
      oe |= 2;
      var u = F2();
      (Fe !== e || Te !== t) && ((Ht = null), (er = Ee() + 500), jn(e, t));
      do
        try {
          du();
          break;
        } catch (C) {
          _2(e, C);
        }
      while (!0);
      (Ni(),
        (W1.current = u),
        (oe = o),
        ke !== null ? (t = 0) : ((Fe = null), (Te = 0), (t = Me)));
    }
    if (t !== 0) {
      if (
        (t === 2 && ((o = Bl(e)), o !== 0 && ((l = o), (t = s0(e, o)))),
        t === 1)
      )
        throw ((n = Ur), jn(e, 0), sn(e, l), Xe(e, Ee()), n);
      if (t === 6) sn(e, l);
      else {
        if (
          ((o = e.current.alternate),
          (l & 30) === 0 &&
            !uu(o) &&
            ((t = J1(e, l)),
            t === 2 && ((u = Bl(e)), u !== 0 && ((l = u), (t = s0(e, u)))),
            t === 1))
        )
          throw ((n = Ur), jn(e, 0), sn(e, l), Xe(e, Ee()), n);
        switch (((e.finishedWork = o), (e.finishedLanes = l), t)) {
          case 0:
          case 1:
            throw Error(a(345));
          case 2:
            Nn(e, Ye, Ht);
            break;
          case 3:
            if (
              (sn(e, l),
              (l & 130023424) === l && ((t = r0 + 500 - Ee()), 10 < t))
            ) {
              if (s1(e, 0) !== 0) break;
              if (((o = e.suspendedLanes), (o & l) !== l)) {
                ($e(), (e.pingedLanes |= e.suspendedLanes & o));
                break;
              }
              e.timeoutHandle = fi(Nn.bind(null, e, Ye, Ht), t);
              break;
            }
            Nn(e, Ye, Ht);
            break;
          case 4:
            if ((sn(e, l), (l & 4194240) === l)) break;
            for (t = e.eventTimes, o = -1; 0 < l; ) {
              var f = 31 - ht(l);
              ((u = 1 << f), (f = t[f]), f > o && (o = f), (l &= ~u));
            }
            if (
              ((l = o),
              (l = Ee() - l),
              (l =
                (120 > l
                  ? 120
                  : 480 > l
                    ? 480
                    : 1080 > l
                      ? 1080
                      : 1920 > l
                        ? 1920
                        : 3e3 > l
                          ? 3e3
                          : 4320 > l
                            ? 4320
                            : 1960 * au(l / 1960)) - l),
              10 < l)
            ) {
              e.timeoutHandle = fi(Nn.bind(null, e, Ye, Ht), l);
              break;
            }
            Nn(e, Ye, Ht);
            break;
          case 5:
            Nn(e, Ye, Ht);
            break;
          default:
            throw Error(a(329));
        }
      }
    }
    return (Xe(e, Ee()), e.callbackNode === n ? P2.bind(null, e) : null);
  }
  function s0(e, t) {
    var n = Zr;
    return (
      e.current.memoizedState.isDehydrated && (jn(e, t).flags |= 256),
      (e = J1(e, t)),
      e !== 2 && ((t = Ye), (Ye = n), t !== null && o0(t)),
      e
    );
  }
  function o0(e) {
    Ye === null ? (Ye = e) : Ye.push.apply(Ye, e);
  }
  function uu(e) {
    for (var t = e; ; ) {
      if (t.flags & 16384) {
        var n = t.updateQueue;
        if (n !== null && ((n = n.stores), n !== null))
          for (var l = 0; l < n.length; l++) {
            var o = n[l],
              u = o.getSnapshot;
            o = o.value;
            try {
              if (!pt(u(), o)) return !1;
            } catch {
              return !1;
            }
          }
      }
      if (((n = t.child), t.subtreeFlags & 16384 && n !== null))
        ((n.return = t), (t = n));
      else {
        if (t === e) break;
        for (; t.sibling === null; ) {
          if (t.return === null || t.return === e) return !0;
          t = t.return;
        }
        ((t.sibling.return = t.return), (t = t.sibling));
      }
    }
    return !0;
  }
  function sn(e, t) {
    for (
      t &= ~n0,
        t &= ~$1,
        e.suspendedLanes |= t,
        e.pingedLanes &= ~t,
        e = e.expirationTimes;
      0 < t;

    ) {
      var n = 31 - ht(t),
        l = 1 << n;
      ((e[n] = -1), (t &= ~l));
    }
  }
  function O2(e) {
    if ((oe & 6) !== 0) throw Error(a(327));
    tr();
    var t = s1(e, 0);
    if ((t & 1) === 0) return (Xe(e, Ee()), null);
    var n = J1(e, t);
    if (e.tag !== 0 && n === 2) {
      var l = Bl(e);
      l !== 0 && ((t = l), (n = s0(e, l)));
    }
    if (n === 1) throw ((n = Ur), jn(e, 0), sn(e, t), Xe(e, Ee()), n);
    if (n === 6) throw Error(a(345));
    return (
      (e.finishedWork = e.current.alternate),
      (e.finishedLanes = t),
      Nn(e, Ye, Ht),
      Xe(e, Ee()),
      null
    );
  }
  function a0(e, t) {
    var n = oe;
    oe |= 1;
    try {
      return e(t);
    } finally {
      ((oe = n), oe === 0 && ((er = Ee() + 500), E1 && Jt()));
    }
  }
  function yn(e) {
    rn !== null && rn.tag === 0 && (oe & 6) === 0 && tr();
    var t = oe;
    oe |= 1;
    var n = ft.transition,
      l = me;
    try {
      if (((ft.transition = null), (me = 1), e)) return e();
    } finally {
      ((me = l), (ft.transition = n), (oe = t), (oe & 6) === 0 && Jt());
    }
  }
  function u0() {
    ((it = qn.current), ve(qn));
  }
  function jn(e, t) {
    ((e.finishedWork = null), (e.finishedLanes = 0));
    var n = e.timeoutHandle;
    if ((n !== -1 && ((e.timeoutHandle = -1), B3(n)), ke !== null))
      for (n = ke.return; n !== null; ) {
        var l = n;
        switch ((vi(l), l.tag)) {
          case 1:
            ((l = l.type.childContextTypes), l != null && N1());
            break;
          case 3:
            (Yn(), ve(Ge), ve(He), Pi());
            break;
          case 5:
            Mi(l);
            break;
          case 4:
            Yn();
            break;
          case 13:
            ve(ye);
            break;
          case 19:
            ve(ye);
            break;
          case 10:
            Li(l.type._context);
            break;
          case 22:
          case 23:
            u0();
        }
        n = n.return;
      }
    if (
      ((Fe = e),
      (ke = e = on(e.current, null)),
      (Te = it = t),
      (Me = 0),
      (Ur = null),
      (n0 = $1 = wn = 0),
      (Ye = Zr = null),
      Cn !== null)
    ) {
      for (t = 0; t < Cn.length; t++)
        if (((n = Cn[t]), (l = n.interleaved), l !== null)) {
          n.interleaved = null;
          var o = l.next,
            u = n.pending;
          if (u !== null) {
            var f = u.next;
            ((u.next = o), (l.next = f));
          }
          n.pending = l;
        }
      Cn = null;
    }
    return e;
  }
  function _2(e, t) {
    do {
      var n = ke;
      try {
        if ((Ni(), (I1.current = B1), D1)) {
          for (var l = je.memoizedState; l !== null; ) {
            var o = l.queue;
            (o !== null && (o.pending = null), (l = l.next));
          }
          D1 = !1;
        }
        if (
          ((gn = 0),
          (_e = Re = je = null),
          (Tr = !1),
          (Ar = 0),
          (t0.current = null),
          n === null || n.return === null)
        ) {
          ((Me = 1), (Ur = t), (ke = null));
          break;
        }
        e: {
          var u = e,
            f = n.return,
            C = n,
            g = t;
          if (
            ((t = Te),
            (C.flags |= 32768),
            g !== null && typeof g == "object" && typeof g.then == "function")
          ) {
            var R = g,
              D = C,
              A = D.tag;
            if ((D.mode & 1) === 0 && (A === 0 || A === 11 || A === 15)) {
              var _ = D.alternate;
              _
                ? ((D.updateQueue = _.updateQueue),
                  (D.memoizedState = _.memoizedState),
                  (D.lanes = _.lanes))
                : ((D.updateQueue = null), (D.memoizedState = null));
            }
            var z = l2(f);
            if (z !== null) {
              ((z.flags &= -257),
                i2(z, f, C, u, t),
                z.mode & 1 && r2(u, R, t),
                (t = z),
                (g = R));
              var $ = t.updateQueue;
              if ($ === null) {
                var G = new Set();
                (G.add(g), (t.updateQueue = G));
              } else $.add(g);
              break e;
            } else {
              if ((t & 1) === 0) {
                (r2(u, R, t), c0());
                break e;
              }
              g = Error(a(426));
            }
          } else if (we && C.mode & 1) {
            var Se = l2(f);
            if (Se !== null) {
              ((Se.flags & 65536) === 0 && (Se.flags |= 256),
                i2(Se, f, C, u, t),
                yi(Xn(g, C)));
              break e;
            }
          }
          ((u = g = Xn(g, C)),
            Me !== 4 && (Me = 2),
            Zr === null ? (Zr = [u]) : Zr.push(u),
            (u = f));
          do {
            switch (u.tag) {
              case 3:
                ((u.flags |= 65536), (t &= -t), (u.lanes |= t));
                var E = t2(u, g, t);
                Ro(u, E);
                break e;
              case 1:
                C = g;
                var w = u.type,
                  S = u.stateNode;
                if (
                  (u.flags & 128) === 0 &&
                  (typeof w.getDerivedStateFromError == "function" ||
                    (S !== null &&
                      typeof S.componentDidCatch == "function" &&
                      (nn === null || !nn.has(S))))
                ) {
                  ((u.flags |= 65536), (t &= -t), (u.lanes |= t));
                  var B = n2(u, C, t);
                  Ro(u, B);
                  break e;
                }
            }
            u = u.return;
          } while (u !== null);
        }
        D2(n);
      } catch (Q) {
        ((t = Q), ke === n && n !== null && (ke = n = n.return));
        continue;
      }
      break;
    } while (!0);
  }
  function F2() {
    var e = W1.current;
    return ((W1.current = B1), e === null ? B1 : e);
  }
  function c0() {
    ((Me === 0 || Me === 3 || Me === 2) && (Me = 4),
      Fe === null ||
        ((wn & 268435455) === 0 && ($1 & 268435455) === 0) ||
        sn(Fe, Te));
  }
  function J1(e, t) {
    var n = oe;
    oe |= 2;
    var l = F2();
    (Fe !== e || Te !== t) && ((Ht = null), jn(e, t));
    do
      try {
        cu();
        break;
      } catch (o) {
        _2(e, o);
      }
    while (!0);
    if ((Ni(), (oe = n), (W1.current = l), ke !== null)) throw Error(a(261));
    return ((Fe = null), (Te = 0), Me);
  }
  function cu() {
    for (; ke !== null; ) I2(ke);
  }
  function du() {
    for (; ke !== null && !D5(); ) I2(ke);
  }
  function I2(e) {
    var t = B2(e.alternate, e, it);
    ((e.memoizedProps = e.pendingProps),
      t === null ? D2(e) : (ke = t),
      (t0.current = null));
  }
  function D2(e) {
    var t = e;
    do {
      var n = t.alternate;
      if (((e = t.return), (t.flags & 32768) === 0)) {
        if (((n = ru(n, t, it)), n !== null)) {
          ke = n;
          return;
        }
      } else {
        if (((n = lu(n, t)), n !== null)) {
          ((n.flags &= 32767), (ke = n));
          return;
        }
        if (e !== null)
          ((e.flags |= 32768), (e.subtreeFlags = 0), (e.deletions = null));
        else {
          ((Me = 6), (ke = null));
          return;
        }
      }
      if (((t = t.sibling), t !== null)) {
        ke = t;
        return;
      }
      ke = t = e;
    } while (t !== null);
    Me === 0 && (Me = 5);
  }
  function Nn(e, t, n) {
    var l = me,
      o = ft.transition;
    try {
      ((ft.transition = null), (me = 1), fu(e, t, n, l));
    } finally {
      ((ft.transition = o), (me = l));
    }
    return null;
  }
  function fu(e, t, n, l) {
    do tr();
    while (rn !== null);
    if ((oe & 6) !== 0) throw Error(a(327));
    n = e.finishedWork;
    var o = e.finishedLanes;
    if (n === null) return null;
    if (((e.finishedWork = null), (e.finishedLanes = 0), n === e.current))
      throw Error(a(177));
    ((e.callbackNode = null), (e.callbackPriority = 0));
    var u = n.lanes | n.childLanes;
    if (
      ($5(e, u),
      e === Fe && ((ke = Fe = null), (Te = 0)),
      ((n.subtreeFlags & 2064) === 0 && (n.flags & 2064) === 0) ||
        Q1 ||
        ((Q1 = !0),
        H2(n1, function () {
          return (tr(), null);
        })),
      (u = (n.flags & 15990) !== 0),
      (n.subtreeFlags & 15990) !== 0 || u)
    ) {
      ((u = ft.transition), (ft.transition = null));
      var f = me;
      me = 1;
      var C = oe;
      ((oe |= 4),
        (t0.current = null),
        su(e, n),
        S2(n, e),
        O3(ci),
        (u1 = !!ui),
        (ci = ui = null),
        (e.current = n),
        ou(n),
        T5(),
        (oe = C),
        (me = f),
        (ft.transition = u));
    } else e.current = n;
    if (
      (Q1 && ((Q1 = !1), (rn = e), (K1 = o)),
      (u = e.pendingLanes),
      u === 0 && (nn = null),
      H5(n.stateNode),
      Xe(e, Ee()),
      t !== null)
    )
      for (l = e.onRecoverableError, n = 0; n < t.length; n++)
        ((o = t[n]), l(o.value, { componentStack: o.stack, digest: o.digest }));
    if (G1) throw ((G1 = !1), (e = l0), (l0 = null), e);
    return (
      (K1 & 1) !== 0 && e.tag !== 0 && tr(),
      (u = e.pendingLanes),
      (u & 1) !== 0 ? (e === i0 ? Wr++ : ((Wr = 0), (i0 = e))) : (Wr = 0),
      Jt(),
      null
    );
  }
  function tr() {
    if (rn !== null) {
      var e = Ns(K1),
        t = ft.transition,
        n = me;
      try {
        if (((ft.transition = null), (me = 16 > e ? 16 : e), rn === null))
          var l = !1;
        else {
          if (((e = rn), (rn = null), (K1 = 0), (oe & 6) !== 0))
            throw Error(a(331));
          var o = oe;
          for (oe |= 4, U = e.current; U !== null; ) {
            var u = U,
              f = u.child;
            if ((U.flags & 16) !== 0) {
              var C = u.deletions;
              if (C !== null) {
                for (var g = 0; g < C.length; g++) {
                  var R = C[g];
                  for (U = R; U !== null; ) {
                    var D = U;
                    switch (D.tag) {
                      case 0:
                      case 11:
                      case 15:
                        zr(8, D, u);
                    }
                    var A = D.child;
                    if (A !== null) ((A.return = D), (U = A));
                    else
                      for (; U !== null; ) {
                        D = U;
                        var _ = D.sibling,
                          z = D.return;
                        if ((y2(D), D === R)) {
                          U = null;
                          break;
                        }
                        if (_ !== null) {
                          ((_.return = z), (U = _));
                          break;
                        }
                        U = z;
                      }
                  }
                }
                var $ = u.alternate;
                if ($ !== null) {
                  var G = $.child;
                  if (G !== null) {
                    $.child = null;
                    do {
                      var Se = G.sibling;
                      ((G.sibling = null), (G = Se));
                    } while (G !== null);
                  }
                }
                U = u;
              }
            }
            if ((u.subtreeFlags & 2064) !== 0 && f !== null)
              ((f.return = u), (U = f));
            else
              e: for (; U !== null; ) {
                if (((u = U), (u.flags & 2048) !== 0))
                  switch (u.tag) {
                    case 0:
                    case 11:
                    case 15:
                      zr(9, u, u.return);
                  }
                var E = u.sibling;
                if (E !== null) {
                  ((E.return = u.return), (U = E));
                  break e;
                }
                U = u.return;
              }
          }
          var w = e.current;
          for (U = w; U !== null; ) {
            f = U;
            var S = f.child;
            if ((f.subtreeFlags & 2064) !== 0 && S !== null)
              ((S.return = f), (U = S));
            else
              e: for (f = w; U !== null; ) {
                if (((C = U), (C.flags & 2048) !== 0))
                  try {
                    switch (C.tag) {
                      case 0:
                      case 11:
                      case 15:
                        Z1(9, C);
                    }
                  } catch (Q) {
                    Ne(C, C.return, Q);
                  }
                if (C === f) {
                  U = null;
                  break e;
                }
                var B = C.sibling;
                if (B !== null) {
                  ((B.return = C.return), (U = B));
                  break e;
                }
                U = C.return;
              }
          }
          if (
            ((oe = o),
            Jt(),
            kt && typeof kt.onPostCommitFiberRoot == "function")
          )
            try {
              kt.onPostCommitFiberRoot(r1, e);
            } catch {}
          l = !0;
        }
        return l;
      } finally {
        ((me = n), (ft.transition = t));
      }
    }
    return !1;
  }
  function T2(e, t, n) {
    ((t = Xn(n, t)),
      (t = t2(e, t, 1)),
      (e = en(e, t, 1)),
      (t = $e()),
      e !== null && (pr(e, 1, t), Xe(e, t)));
  }
  function Ne(e, t, n) {
    if (e.tag === 3) T2(e, e, n);
    else
      for (; t !== null; ) {
        if (t.tag === 3) {
          T2(t, e, n);
          break;
        } else if (t.tag === 1) {
          var l = t.stateNode;
          if (
            typeof t.type.getDerivedStateFromError == "function" ||
            (typeof l.componentDidCatch == "function" &&
              (nn === null || !nn.has(l)))
          ) {
            ((e = Xn(n, e)),
              (e = n2(t, e, 1)),
              (t = en(t, e, 1)),
              (e = $e()),
              t !== null && (pr(t, 1, e), Xe(t, e)));
            break;
          }
        }
        t = t.return;
      }
  }
  function mu(e, t, n) {
    var l = e.pingCache;
    (l !== null && l.delete(t),
      (t = $e()),
      (e.pingedLanes |= e.suspendedLanes & n),
      Fe === e &&
        (Te & n) === n &&
        (Me === 4 || (Me === 3 && (Te & 130023424) === Te && 500 > Ee() - r0)
          ? jn(e, 0)
          : (n0 |= n)),
      Xe(e, t));
  }
  function A2(e, t) {
    t === 0 &&
      ((e.mode & 1) === 0
        ? (t = 1)
        : ((t = i1), (i1 <<= 1), (i1 & 130023424) === 0 && (i1 = 4194304)));
    var n = $e();
    ((e = Tt(e, t)), e !== null && (pr(e, t, n), Xe(e, n)));
  }
  function hu(e) {
    var t = e.memoizedState,
      n = 0;
    (t !== null && (n = t.retryLane), A2(e, n));
  }
  function pu(e, t) {
    var n = 0;
    switch (e.tag) {
      case 13:
        var l = e.stateNode,
          o = e.memoizedState;
        o !== null && (n = o.retryLane);
        break;
      case 19:
        l = e.stateNode;
        break;
      default:
        throw Error(a(314));
    }
    (l !== null && l.delete(t), A2(e, n));
  }
  var B2;
  B2 = function (e, t, n) {
    if (e !== null)
      if (e.memoizedProps !== t.pendingProps || Ge.current) Ke = !0;
      else {
        if ((e.lanes & n) === 0 && (t.flags & 128) === 0)
          return ((Ke = !1), nu(e, t, n));
        Ke = (e.flags & 131072) !== 0;
      }
    else ((Ke = !1), we && (t.flags & 1048576) !== 0 && vo(t, k1, t.index));
    switch (((t.lanes = 0), t.tag)) {
      case 2:
        var l = t.type;
        (z1(e, t), (e = t.pendingProps));
        var o = Un(t, He.current);
        (Kn(t, n), (o = Fi(null, t, l, e, o, n)));
        var u = Ii();
        return (
          (t.flags |= 1),
          typeof o == "object" &&
          o !== null &&
          typeof o.render == "function" &&
          o.$$typeof === void 0
            ? ((t.tag = 1),
              (t.memoizedState = null),
              (t.updateQueue = null),
              Qe(l) ? ((u = !0), L1(t)) : (u = !1),
              (t.memoizedState =
                o.state !== null && o.state !== void 0 ? o.state : null),
              ki(t),
              (o.updater = H1),
              (t.stateNode = o),
              (o._reactInternals = t),
              Vi(t, l, e, n),
              (t = Wi(null, t, l, !0, u, n)))
            : ((t.tag = 0), we && u && Ci(t), We(null, t, o, n), (t = t.child)),
          t
        );
      case 16:
        l = t.elementType;
        e: {
          switch (
            (z1(e, t),
            (e = t.pendingProps),
            (o = l._init),
            (l = o(l._payload)),
            (t.type = l),
            (o = t.tag = Cu(l)),
            (e = Ct(l, e)),
            o)
          ) {
            case 0:
              t = Zi(null, t, l, e, n);
              break e;
            case 1:
              t = d2(null, t, l, e, n);
              break e;
            case 11:
              t = s2(null, t, l, e, n);
              break e;
            case 14:
              t = o2(null, t, l, Ct(l.type, e), n);
              break e;
          }
          throw Error(a(306, l, ""));
        }
        return t;
      case 0:
        return (
          (l = t.type),
          (o = t.pendingProps),
          (o = t.elementType === l ? o : Ct(l, o)),
          Zi(e, t, l, o, n)
        );
      case 1:
        return (
          (l = t.type),
          (o = t.pendingProps),
          (o = t.elementType === l ? o : Ct(l, o)),
          d2(e, t, l, o, n)
        );
      case 3:
        e: {
          if ((f2(t), e === null)) throw Error(a(387));
          ((l = t.pendingProps),
            (u = t.memoizedState),
            (o = u.element),
            ko(e, t),
            _1(t, l, null, n));
          var f = t.memoizedState;
          if (((l = f.element), u.isDehydrated))
            if (
              ((u = {
                element: l,
                isDehydrated: !1,
                cache: f.cache,
                pendingSuspenseBoundaries: f.pendingSuspenseBoundaries,
                transitions: f.transitions,
              }),
              (t.updateQueue.baseState = u),
              (t.memoizedState = u),
              t.flags & 256)
            ) {
              ((o = Xn(Error(a(423)), t)), (t = m2(e, t, l, n, o)));
              break e;
            } else if (l !== o) {
              ((o = Xn(Error(a(424)), t)), (t = m2(e, t, l, n, o)));
              break e;
            } else
              for (
                lt = Kt(t.stateNode.containerInfo.firstChild),
                  rt = t,
                  we = !0,
                  xt = null,
                  n = Eo(t, null, l, n),
                  t.child = n;
                n;

              )
                ((n.flags = (n.flags & -3) | 4096), (n = n.sibling));
          else {
            if (($n(), l === o)) {
              t = Bt(e, t, n);
              break e;
            }
            We(e, t, l, n);
          }
          t = t.child;
        }
        return t;
      case 5:
        return (
          bo(t),
          e === null && wi(t),
          (l = t.type),
          (o = t.pendingProps),
          (u = e !== null ? e.memoizedProps : null),
          (f = o.children),
          di(l, o) ? (f = null) : u !== null && di(l, u) && (t.flags |= 32),
          c2(e, t),
          We(e, t, f, n),
          t.child
        );
      case 6:
        return (e === null && wi(t), null);
      case 13:
        return h2(e, t, n);
      case 4:
        return (
          Ri(t, t.stateNode.containerInfo),
          (l = t.pendingProps),
          e === null ? (t.child = Gn(t, null, l, n)) : We(e, t, l, n),
          t.child
        );
      case 11:
        return (
          (l = t.type),
          (o = t.pendingProps),
          (o = t.elementType === l ? o : Ct(l, o)),
          s2(e, t, l, o, n)
        );
      case 7:
        return (We(e, t, t.pendingProps, n), t.child);
      case 8:
        return (We(e, t, t.pendingProps.children, n), t.child);
      case 12:
        return (We(e, t, t.pendingProps.children, n), t.child);
      case 10:
        e: {
          if (
            ((l = t.type._context),
            (o = t.pendingProps),
            (u = t.memoizedProps),
            (f = o.value),
            pe(b1, l._currentValue),
            (l._currentValue = f),
            u !== null)
          )
            if (pt(u.value, f)) {
              if (u.children === o.children && !Ge.current) {
                t = Bt(e, t, n);
                break e;
              }
            } else
              for (u = t.child, u !== null && (u.return = t); u !== null; ) {
                var C = u.dependencies;
                if (C !== null) {
                  f = u.child;
                  for (var g = C.firstContext; g !== null; ) {
                    if (g.context === l) {
                      if (u.tag === 1) {
                        ((g = At(-1, n & -n)), (g.tag = 2));
                        var R = u.updateQueue;
                        if (R !== null) {
                          R = R.shared;
                          var D = R.pending;
                          (D === null
                            ? (g.next = g)
                            : ((g.next = D.next), (D.next = g)),
                            (R.pending = g));
                        }
                      }
                      ((u.lanes |= n),
                        (g = u.alternate),
                        g !== null && (g.lanes |= n),
                        Ei(u.return, n, t),
                        (C.lanes |= n));
                      break;
                    }
                    g = g.next;
                  }
                } else if (u.tag === 10) f = u.type === t.type ? null : u.child;
                else if (u.tag === 18) {
                  if (((f = u.return), f === null)) throw Error(a(341));
                  ((f.lanes |= n),
                    (C = f.alternate),
                    C !== null && (C.lanes |= n),
                    Ei(f, n, t),
                    (f = u.sibling));
                } else f = u.child;
                if (f !== null) f.return = u;
                else
                  for (f = u; f !== null; ) {
                    if (f === t) {
                      f = null;
                      break;
                    }
                    if (((u = f.sibling), u !== null)) {
                      ((u.return = f.return), (f = u));
                      break;
                    }
                    f = f.return;
                  }
                u = f;
              }
          (We(e, t, o.children, n), (t = t.child));
        }
        return t;
      case 9:
        return (
          (o = t.type),
          (l = t.pendingProps.children),
          Kn(t, n),
          (o = ct(o)),
          (l = l(o)),
          (t.flags |= 1),
          We(e, t, l, n),
          t.child
        );
      case 14:
        return (
          (l = t.type),
          (o = Ct(l, t.pendingProps)),
          (o = Ct(l.type, o)),
          o2(e, t, l, o, n)
        );
      case 15:
        return a2(e, t, t.type, t.pendingProps, n);
      case 17:
        return (
          (l = t.type),
          (o = t.pendingProps),
          (o = t.elementType === l ? o : Ct(l, o)),
          z1(e, t),
          (t.tag = 1),
          Qe(l) ? ((e = !0), L1(t)) : (e = !1),
          Kn(t, n),
          qo(t, l, o),
          Vi(t, l, o, n),
          Wi(null, t, l, !0, e, n)
        );
      case 19:
        return x2(e, t, n);
      case 22:
        return u2(e, t, n);
    }
    throw Error(a(156, t.tag));
  };
  function H2(e, t) {
    return vs(e, t);
  }
  function xu(e, t, n, l) {
    ((this.tag = e),
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
      (this.mode = l),
      (this.subtreeFlags = this.flags = 0),
      (this.deletions = null),
      (this.childLanes = this.lanes = 0),
      (this.alternate = null));
  }
  function mt(e, t, n, l) {
    return new xu(e, t, n, l);
  }
  function d0(e) {
    return ((e = e.prototype), !(!e || !e.isReactComponent));
  }
  function Cu(e) {
    if (typeof e == "function") return d0(e) ? 1 : 0;
    if (e != null) {
      if (((e = e.$$typeof), e === Oe)) return 11;
      if (e === ot) return 14;
    }
    return 2;
  }
  function on(e, t) {
    var n = e.alternate;
    return (
      n === null
        ? ((n = mt(e.tag, t, e.key, e.mode)),
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
  function q1(e, t, n, l, o, u) {
    var f = 2;
    if (((l = e), typeof e == "function")) d0(e) && (f = 1);
    else if (typeof e == "string") f = 5;
    else
      e: switch (e) {
        case Y:
          return Ln(n.children, o, u, t);
        case de:
          ((f = 8), (o |= 8));
          break;
        case Pe:
          return (
            (e = mt(12, n, t, o | 2)),
            (e.elementType = Pe),
            (e.lanes = u),
            e
          );
        case Le:
          return (
            (e = mt(13, n, t, o)),
            (e.elementType = Le),
            (e.lanes = u),
            e
          );
        case et:
          return (
            (e = mt(19, n, t, o)),
            (e.elementType = et),
            (e.lanes = u),
            e
          );
        case xe:
          return el(n, o, u, t);
        default:
          if (typeof e == "object" && e !== null)
            switch (e.$$typeof) {
              case Ae:
                f = 10;
                break e;
              case st:
                f = 9;
                break e;
              case Oe:
                f = 11;
                break e;
              case ot:
                f = 14;
                break e;
              case Be:
                ((f = 16), (l = null));
                break e;
            }
          throw Error(a(130, e == null ? e : typeof e, ""));
      }
    return (
      (t = mt(f, n, t, o)),
      (t.elementType = e),
      (t.type = l),
      (t.lanes = u),
      t
    );
  }
  function Ln(e, t, n, l) {
    return ((e = mt(7, e, l, t)), (e.lanes = n), e);
  }
  function el(e, t, n, l) {
    return (
      (e = mt(22, e, l, t)),
      (e.elementType = xe),
      (e.lanes = n),
      (e.stateNode = { isHidden: !1 }),
      e
    );
  }
  function f0(e, t, n) {
    return ((e = mt(6, e, null, t)), (e.lanes = n), e);
  }
  function m0(e, t, n) {
    return (
      (t = mt(4, e.children !== null ? e.children : [], e.key, t)),
      (t.lanes = n),
      (t.stateNode = {
        containerInfo: e.containerInfo,
        pendingChildren: null,
        implementation: e.implementation,
      }),
      t
    );
  }
  function vu(e, t, n, l, o) {
    ((this.tag = t),
      (this.containerInfo = e),
      (this.finishedWork =
        this.pingCache =
        this.current =
        this.pendingChildren =
          null),
      (this.timeoutHandle = -1),
      (this.callbackNode = this.pendingContext = this.context = null),
      (this.callbackPriority = 0),
      (this.eventTimes = Hl(0)),
      (this.expirationTimes = Hl(-1)),
      (this.entangledLanes =
        this.finishedLanes =
        this.mutableReadLanes =
        this.expiredLanes =
        this.pingedLanes =
        this.suspendedLanes =
        this.pendingLanes =
          0),
      (this.entanglements = Hl(0)),
      (this.identifierPrefix = l),
      (this.onRecoverableError = o),
      (this.mutableSourceEagerHydrationData = null));
  }
  function h0(e, t, n, l, o, u, f, C, g) {
    return (
      (e = new vu(e, t, n, C, g)),
      t === 1 ? ((t = 1), u === !0 && (t |= 8)) : (t = 0),
      (u = mt(3, null, null, t)),
      (e.current = u),
      (u.stateNode = e),
      (u.memoizedState = {
        element: l,
        isDehydrated: n,
        cache: null,
        transitions: null,
        pendingSuspenseBoundaries: null,
      }),
      ki(u),
      e
    );
  }
  function gu(e, t, n) {
    var l =
      3 < arguments.length && arguments[3] !== void 0 ? arguments[3] : null;
    return {
      $$typeof: K,
      key: l == null ? null : "" + l,
      children: e,
      containerInfo: t,
      implementation: n,
    };
  }
  function V2(e) {
    if (!e) return Xt;
    e = e._reactInternals;
    e: {
      if (fn(e) !== e || e.tag !== 1) throw Error(a(170));
      var t = e;
      do {
        switch (t.tag) {
          case 3:
            t = t.stateNode.context;
            break e;
          case 1:
            if (Qe(t.type)) {
              t = t.stateNode.__reactInternalMemoizedMergedChildContext;
              break e;
            }
        }
        t = t.return;
      } while (t !== null);
      throw Error(a(171));
    }
    if (e.tag === 1) {
      var n = e.type;
      if (Qe(n)) return po(e, n, t);
    }
    return t;
  }
  function z2(e, t, n, l, o, u, f, C, g) {
    return (
      (e = h0(n, l, !0, e, o, u, f, C, g)),
      (e.context = V2(null)),
      (n = e.current),
      (l = $e()),
      (o = ln(n)),
      (u = At(l, o)),
      (u.callback = t ?? null),
      en(n, u, o),
      (e.current.lanes = o),
      pr(e, o, l),
      Xe(e, l),
      e
    );
  }
  function tl(e, t, n, l) {
    var o = t.current,
      u = $e(),
      f = ln(o);
    return (
      (n = V2(n)),
      t.context === null ? (t.context = n) : (t.pendingContext = n),
      (t = At(u, f)),
      (t.payload = { element: e }),
      (l = l === void 0 ? null : l),
      l !== null && (t.callback = l),
      (e = en(o, t, f)),
      e !== null && (wt(e, o, f, u), O1(e, o, f)),
      f
    );
  }
  function nl(e) {
    if (((e = e.current), !e.child)) return null;
    switch (e.child.tag) {
      case 5:
        return e.child.stateNode;
      default:
        return e.child.stateNode;
    }
  }
  function U2(e, t) {
    if (((e = e.memoizedState), e !== null && e.dehydrated !== null)) {
      var n = e.retryLane;
      e.retryLane = n !== 0 && n < t ? n : t;
    }
  }
  function p0(e, t) {
    (U2(e, t), (e = e.alternate) && U2(e, t));
  }
  function wu() {
    return null;
  }
  var Z2 =
    typeof reportError == "function"
      ? reportError
      : function (e) {
          console.error(e);
        };
  function x0(e) {
    this._internalRoot = e;
  }
  ((rl.prototype.render = x0.prototype.render =
    function (e) {
      var t = this._internalRoot;
      if (t === null) throw Error(a(409));
      tl(e, t, null, null);
    }),
    (rl.prototype.unmount = x0.prototype.unmount =
      function () {
        var e = this._internalRoot;
        if (e !== null) {
          this._internalRoot = null;
          var t = e.containerInfo;
          (yn(function () {
            tl(null, e, null, null);
          }),
            (t[_t] = null));
        }
      }));
  function rl(e) {
    this._internalRoot = e;
  }
  rl.prototype.unstable_scheduleHydration = function (e) {
    if (e) {
      var t = Ss();
      e = { blockedOn: null, target: e, priority: t };
      for (var n = 0; n < $t.length && t !== 0 && t < $t[n].priority; n++);
      ($t.splice(n, 0, e), n === 0 && Ms(e));
    }
  };
  function C0(e) {
    return !(!e || (e.nodeType !== 1 && e.nodeType !== 9 && e.nodeType !== 11));
  }
  function ll(e) {
    return !(
      !e ||
      (e.nodeType !== 1 &&
        e.nodeType !== 9 &&
        e.nodeType !== 11 &&
        (e.nodeType !== 8 || e.nodeValue !== " react-mount-point-unstable "))
    );
  }
  function W2() {}
  function yu(e, t, n, l, o) {
    if (o) {
      if (typeof l == "function") {
        var u = l;
        l = function () {
          var R = nl(f);
          u.call(R);
        };
      }
      var f = z2(t, l, e, 0, null, !1, !1, "", W2);
      return (
        (e._reactRootContainer = f),
        (e[_t] = f.current),
        Mr(e.nodeType === 8 ? e.parentNode : e),
        yn(),
        f
      );
    }
    for (; (o = e.lastChild); ) e.removeChild(o);
    if (typeof l == "function") {
      var C = l;
      l = function () {
        var R = nl(g);
        C.call(R);
      };
    }
    var g = h0(e, 0, !1, null, null, !1, !1, "", W2);
    return (
      (e._reactRootContainer = g),
      (e[_t] = g.current),
      Mr(e.nodeType === 8 ? e.parentNode : e),
      yn(function () {
        tl(t, g, n, l);
      }),
      g
    );
  }
  function il(e, t, n, l, o) {
    var u = n._reactRootContainer;
    if (u) {
      var f = u;
      if (typeof o == "function") {
        var C = o;
        o = function () {
          var g = nl(f);
          C.call(g);
        };
      }
      tl(t, f, e, o);
    } else f = yu(n, t, e, o, l);
    return nl(f);
  }
  ((Ls = function (e) {
    switch (e.tag) {
      case 3:
        var t = e.stateNode;
        if (t.current.memoizedState.isDehydrated) {
          var n = hr(t.pendingLanes);
          n !== 0 &&
            (Vl(t, n | 1),
            Xe(t, Ee()),
            (oe & 6) === 0 && ((er = Ee() + 500), Jt()));
        }
        break;
      case 13:
        (yn(function () {
          var l = Tt(e, 1);
          if (l !== null) {
            var o = $e();
            wt(l, e, 1, o);
          }
        }),
          p0(e, 1));
    }
  }),
    (zl = function (e) {
      if (e.tag === 13) {
        var t = Tt(e, 134217728);
        if (t !== null) {
          var n = $e();
          wt(t, e, 134217728, n);
        }
        p0(e, 134217728);
      }
    }),
    (Es = function (e) {
      if (e.tag === 13) {
        var t = ln(e),
          n = Tt(e, t);
        if (n !== null) {
          var l = $e();
          wt(n, e, t, l);
        }
        p0(e, t);
      }
    }),
    (Ss = function () {
      return me;
    }),
    (ks = function (e, t) {
      var n = me;
      try {
        return ((me = e), t());
      } finally {
        me = n;
      }
    }),
    (Fl = function (e, t, n) {
      switch (t) {
        case "input":
          if ((Sl(e, n), (t = n.name), n.type === "radio" && t != null)) {
            for (n = e; n.parentNode; ) n = n.parentNode;
            for (
              n = n.querySelectorAll(
                "input[name=" + JSON.stringify("" + t) + '][type="radio"]',
              ),
                t = 0;
              t < n.length;
              t++
            ) {
              var l = n[t];
              if (l !== e && l.form === e.form) {
                var o = j1(l);
                if (!o) throw Error(a(90));
                (X0(l), Sl(l, o));
              }
            }
          }
          break;
        case "textarea":
          ns(e, n);
          break;
        case "select":
          ((t = n.value), t != null && Pn(e, !!n.multiple, t, !1));
      }
    }),
    (ds = a0),
    (fs = yn));
  var ju = { usingClientEntryPoint: !1, Events: [Or, Vn, j1, us, cs, a0] },
    $r = {
      findFiberByHostInstance: mn,
      bundleType: 0,
      version: "18.3.1",
      rendererPackageName: "react-dom",
    },
    Nu = {
      bundleType: $r.bundleType,
      version: $r.version,
      rendererPackageName: $r.rendererPackageName,
      rendererConfig: $r.rendererConfig,
      overrideHookState: null,
      overrideHookStateDeletePath: null,
      overrideHookStateRenamePath: null,
      overrideProps: null,
      overridePropsDeletePath: null,
      overridePropsRenamePath: null,
      setErrorHandler: null,
      setSuspenseHandler: null,
      scheduleUpdate: null,
      currentDispatcherRef: Z.ReactCurrentDispatcher,
      findHostInstanceByFiber: function (e) {
        return ((e = xs(e)), e === null ? null : e.stateNode);
      },
      findFiberByHostInstance: $r.findFiberByHostInstance || wu,
      findHostInstancesForRefresh: null,
      scheduleRefresh: null,
      scheduleRoot: null,
      setRefreshHandler: null,
      getCurrentFiber: null,
      reconcilerVersion: "18.3.1-next-f1338f8080-20240426",
    };
  if (typeof __REACT_DEVTOOLS_GLOBAL_HOOK__ < "u") {
    var sl = __REACT_DEVTOOLS_GLOBAL_HOOK__;
    if (!sl.isDisabled && sl.supportsFiber)
      try {
        ((r1 = sl.inject(Nu)), (kt = sl));
      } catch {}
  }
  return (
    (Je.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = ju),
    (Je.createPortal = function (e, t) {
      var n =
        2 < arguments.length && arguments[2] !== void 0 ? arguments[2] : null;
      if (!C0(t)) throw Error(a(200));
      return gu(e, t, null, n);
    }),
    (Je.createRoot = function (e, t) {
      if (!C0(e)) throw Error(a(299));
      var n = !1,
        l = "",
        o = Z2;
      return (
        t != null &&
          (t.unstable_strictMode === !0 && (n = !0),
          t.identifierPrefix !== void 0 && (l = t.identifierPrefix),
          t.onRecoverableError !== void 0 && (o = t.onRecoverableError)),
        (t = h0(e, 1, !1, null, null, n, !1, l, o)),
        (e[_t] = t.current),
        Mr(e.nodeType === 8 ? e.parentNode : e),
        new x0(t)
      );
    }),
    (Je.findDOMNode = function (e) {
      if (e == null) return null;
      if (e.nodeType === 1) return e;
      var t = e._reactInternals;
      if (t === void 0)
        throw typeof e.render == "function"
          ? Error(a(188))
          : ((e = Object.keys(e).join(",")), Error(a(268, e)));
      return ((e = xs(t)), (e = e === null ? null : e.stateNode), e);
    }),
    (Je.flushSync = function (e) {
      return yn(e);
    }),
    (Je.hydrate = function (e, t, n) {
      if (!ll(t)) throw Error(a(200));
      return il(null, e, t, !0, n);
    }),
    (Je.hydrateRoot = function (e, t, n) {
      if (!C0(e)) throw Error(a(405));
      var l = (n != null && n.hydratedSources) || null,
        o = !1,
        u = "",
        f = Z2;
      if (
        (n != null &&
          (n.unstable_strictMode === !0 && (o = !0),
          n.identifierPrefix !== void 0 && (u = n.identifierPrefix),
          n.onRecoverableError !== void 0 && (f = n.onRecoverableError)),
        (t = z2(t, null, e, 1, n ?? null, o, !1, u, f)),
        (e[_t] = t.current),
        Mr(e),
        l)
      )
        for (e = 0; e < l.length; e++)
          ((n = l[e]),
            (o = n._getVersion),
            (o = o(n._source)),
            t.mutableSourceEagerHydrationData == null
              ? (t.mutableSourceEagerHydrationData = [n, o])
              : t.mutableSourceEagerHydrationData.push(n, o));
      return new rl(t);
    }),
    (Je.render = function (e, t, n) {
      if (!ll(t)) throw Error(a(200));
      return il(null, e, t, !1, n);
    }),
    (Je.unmountComponentAtNode = function (e) {
      if (!ll(e)) throw Error(a(40));
      return e._reactRootContainer
        ? (yn(function () {
            il(null, null, e, !1, function () {
              ((e._reactRootContainer = null), (e[_t] = null));
            });
          }),
          !0)
        : !1;
    }),
    (Je.unstable_batchedUpdates = a0),
    (Je.unstable_renderSubtreeIntoContainer = function (e, t, n, l) {
      if (!ll(n)) throw Error(a(200));
      if (e == null || e._reactInternals === void 0) throw Error(a(38));
      return il(e, t, n, !1, l);
    }),
    (Je.version = "18.3.1-next-f1338f8080-20240426"),
    Je
  );
}
var q2;
function Fa() {
  if (q2) return w0.exports;
  q2 = 1;
  function r() {
    if (
      !(
        typeof __REACT_DEVTOOLS_GLOBAL_HOOK__ > "u" ||
        typeof __REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE != "function"
      )
    )
      try {
        __REACT_DEVTOOLS_GLOBAL_HOOK__.checkDCE(r);
      } catch (s) {
        console.error(s);
      }
  }
  return (r(), (w0.exports = Pu()), w0.exports);
}
var ea;
function Ou() {
  if (ea) return ol;
  ea = 1;
  var r = Fa();
  return ((ol.createRoot = r.createRoot), (ol.hydrateRoot = r.hydrateRoot), ol);
}
var _u = Ou();
const Fu = vl(_u);
var Ia = Fa();
const Iu = vl(Ia);
/**
 * @remix-run/router v1.23.0
 *
 * Copyright (c) Remix Software Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.md file in the root directory of this source tree.
 *
 * @license MIT
 */ function Qr() {
  return (
    (Qr = Object.assign
      ? Object.assign.bind()
      : function (r) {
          for (var s = 1; s < arguments.length; s++) {
            var a = arguments[s];
            for (var c in a)
              Object.prototype.hasOwnProperty.call(a, c) && (r[c] = a[c]);
          }
          return r;
        }),
    Qr.apply(this, arguments)
  );
}
var cn;
(function (r) {
  ((r.Pop = "POP"), (r.Push = "PUSH"), (r.Replace = "REPLACE"));
})(cn || (cn = {}));
const ta = "popstate";
function Du(r) {
  r === void 0 && (r = {});
  function s(c, d) {
    let { pathname: m, search: x, hash: h } = c.location;
    return T0(
      "",
      { pathname: m, search: x, hash: h },
      (d.state && d.state.usr) || null,
      (d.state && d.state.key) || "default",
    );
  }
  function a(c, d) {
    return typeof d == "string" ? d : Ta(d);
  }
  return Au(s, a, null, r);
}
function be(r, s) {
  if (r === !1 || r === null || typeof r > "u") throw new Error(s);
}
function Da(r, s) {
  if (!r) {
    typeof console < "u" && console.warn(s);
    try {
      throw new Error(s);
    } catch {}
  }
}
function Tu() {
  return Math.random().toString(36).substr(2, 8);
}
function na(r, s) {
  return { usr: r.state, key: r.key, idx: s };
}
function T0(r, s, a, c) {
  return (
    a === void 0 && (a = null),
    Qr(
      { pathname: typeof r == "string" ? r : r.pathname, search: "", hash: "" },
      typeof s == "string" ? sr(s) : s,
      { state: a, key: (s && s.key) || c || Tu() },
    )
  );
}
function Ta(r) {
  let { pathname: s = "/", search: a = "", hash: c = "" } = r;
  return (
    a && a !== "?" && (s += a.charAt(0) === "?" ? a : "?" + a),
    c && c !== "#" && (s += c.charAt(0) === "#" ? c : "#" + c),
    s
  );
}
function sr(r) {
  let s = {};
  if (r) {
    let a = r.indexOf("#");
    a >= 0 && ((s.hash = r.substr(a)), (r = r.substr(0, a)));
    let c = r.indexOf("?");
    (c >= 0 && ((s.search = r.substr(c)), (r = r.substr(0, c))),
      r && (s.pathname = r));
  }
  return s;
}
function Au(r, s, a, c) {
  c === void 0 && (c = {});
  let { window: d = document.defaultView, v5Compat: m = !1 } = c,
    x = d.history,
    h = cn.Pop,
    v = null,
    y = M();
  y == null && ((y = 0), x.replaceState(Qr({}, x.state, { idx: y }), ""));
  function M() {
    return (x.state || { idx: null }).idx;
  }
  function j() {
    h = cn.Pop;
    let k = M(),
      P = k == null ? null : k - y;
    ((y = k), v && v({ action: h, location: N.location, delta: P }));
  }
  function b(k, P) {
    h = cn.Push;
    let T = T0(N.location, k, P);
    y = M() + 1;
    let V = na(T, y),
      Z = N.createHref(T);
    try {
      x.pushState(V, "", Z);
    } catch (ee) {
      if (ee instanceof DOMException && ee.name === "DataCloneError") throw ee;
      d.location.assign(Z);
    }
    m && v && v({ action: h, location: N.location, delta: 1 });
  }
  function O(k, P) {
    h = cn.Replace;
    let T = T0(N.location, k, P);
    y = M();
    let V = na(T, y),
      Z = N.createHref(T);
    (x.replaceState(V, "", Z),
      m && v && v({ action: h, location: N.location, delta: 0 }));
  }
  function H(k) {
    let P = d.location.origin !== "null" ? d.location.origin : d.location.href,
      T = typeof k == "string" ? k : Ta(k);
    return (
      (T = T.replace(/ $/, "%20")),
      be(
        P,
        "No window.location.(origin|href) available to create URL for href: " +
          T,
      ),
      new URL(T, P)
    );
  }
  let N = {
    get action() {
      return h;
    },
    get location() {
      return r(d, x);
    },
    listen(k) {
      if (v) throw new Error("A history only accepts one active listener");
      return (
        d.addEventListener(ta, j),
        (v = k),
        () => {
          (d.removeEventListener(ta, j), (v = null));
        }
      );
    },
    createHref(k) {
      return s(d, k);
    },
    createURL: H,
    encodeLocation(k) {
      let P = H(k);
      return { pathname: P.pathname, search: P.search, hash: P.hash };
    },
    push: b,
    replace: O,
    go(k) {
      return x.go(k);
    },
  };
  return N;
}
var ra;
(function (r) {
  ((r.data = "data"),
    (r.deferred = "deferred"),
    (r.redirect = "redirect"),
    (r.error = "error"));
})(ra || (ra = {}));
function Bu(r, s, a) {
  return (a === void 0 && (a = "/"), Hu(r, s, a));
}
function Hu(r, s, a, c) {
  let d = typeof s == "string" ? sr(s) : s,
    m = Ha(d.pathname || "/", a);
  if (m == null) return null;
  let x = Aa(r);
  Vu(x);
  let h = null;
  for (let v = 0; h == null && v < x.length; ++v) {
    let y = qu(m);
    h = Yu(x[v], y);
  }
  return h;
}
function Aa(r, s, a, c) {
  (s === void 0 && (s = []),
    a === void 0 && (a = []),
    c === void 0 && (c = ""));
  let d = (m, x, h) => {
    let v = {
      relativePath: h === void 0 ? m.path || "" : h,
      caseSensitive: m.caseSensitive === !0,
      childrenIndex: x,
      route: m,
    };
    v.relativePath.startsWith("/") &&
      (be(
        v.relativePath.startsWith(c),
        'Absolute route path "' +
          v.relativePath +
          '" nested under path ' +
          ('"' + c + '" is not valid. An absolute child route path ') +
          "must start with the combined path of all its parent routes.",
      ),
      (v.relativePath = v.relativePath.slice(c.length)));
    let y = Sn([c, v.relativePath]),
      M = a.concat(v);
    (m.children &&
      m.children.length > 0 &&
      (be(
        m.index !== !0,
        "Index routes must not have child routes. Please remove " +
          ('all child routes from route path "' + y + '".'),
      ),
      Aa(m.children, s, M, y)),
      !(m.path == null && !m.index) &&
        s.push({ path: y, score: Qu(y, m.index), routesMeta: M }));
  };
  return (
    r.forEach((m, x) => {
      var h;
      if (m.path === "" || !((h = m.path) != null && h.includes("?"))) d(m, x);
      else for (let v of Ba(m.path)) d(m, x, v);
    }),
    s
  );
}
function Ba(r) {
  let s = r.split("/");
  if (s.length === 0) return [];
  let [a, ...c] = s,
    d = a.endsWith("?"),
    m = a.replace(/\?$/, "");
  if (c.length === 0) return d ? [m, ""] : [m];
  let x = Ba(c.join("/")),
    h = [];
  return (
    h.push(...x.map((v) => (v === "" ? m : [m, v].join("/")))),
    d && h.push(...x),
    h.map((v) => (r.startsWith("/") && v === "" ? "/" : v))
  );
}
function Vu(r) {
  r.sort((s, a) =>
    s.score !== a.score
      ? a.score - s.score
      : Ku(
          s.routesMeta.map((c) => c.childrenIndex),
          a.routesMeta.map((c) => c.childrenIndex),
        ),
  );
}
const zu = /^:[\w-]+$/,
  Uu = 3,
  Zu = 2,
  Wu = 1,
  $u = 10,
  Gu = -2,
  la = (r) => r === "*";
function Qu(r, s) {
  let a = r.split("/"),
    c = a.length;
  return (
    a.some(la) && (c += Gu),
    s && (c += Zu),
    a
      .filter((d) => !la(d))
      .reduce((d, m) => d + (zu.test(m) ? Uu : m === "" ? Wu : $u), c)
  );
}
function Ku(r, s) {
  return r.length === s.length && r.slice(0, -1).every((c, d) => c === s[d])
    ? r[r.length - 1] - s[s.length - 1]
    : 0;
}
function Yu(r, s, a) {
  let { routesMeta: c } = r,
    d = {},
    m = "/",
    x = [];
  for (let h = 0; h < c.length; ++h) {
    let v = c[h],
      y = h === c.length - 1,
      M = m === "/" ? s : s.slice(m.length) || "/",
      j = Xu(
        { path: v.relativePath, caseSensitive: v.caseSensitive, end: y },
        M,
      ),
      b = v.route;
    if (!j) return null;
    (Object.assign(d, j.params),
      x.push({
        params: d,
        pathname: Sn([m, j.pathname]),
        pathnameBase: i6(Sn([m, j.pathnameBase])),
        route: b,
      }),
      j.pathnameBase !== "/" && (m = Sn([m, j.pathnameBase])));
  }
  return x;
}
function Xu(r, s) {
  typeof r == "string" && (r = { path: r, caseSensitive: !1, end: !0 });
  let [a, c] = Ju(r.path, r.caseSensitive, r.end),
    d = s.match(a);
  if (!d) return null;
  let m = d[0],
    x = m.replace(/(.)\/+$/, "$1"),
    h = d.slice(1);
  return {
    params: c.reduce((y, M, j) => {
      let { paramName: b, isOptional: O } = M;
      if (b === "*") {
        let N = h[j] || "";
        x = m.slice(0, m.length - N.length).replace(/(.)\/+$/, "$1");
      }
      const H = h[j];
      return (
        O && !H ? (y[b] = void 0) : (y[b] = (H || "").replace(/%2F/g, "/")),
        y
      );
    }, {}),
    pathname: m,
    pathnameBase: x,
    pattern: r,
  };
}
function Ju(r, s, a) {
  (s === void 0 && (s = !1),
    a === void 0 && (a = !0),
    Da(
      r === "*" || !r.endsWith("*") || r.endsWith("/*"),
      'Route path "' +
        r +
        '" will be treated as if it were ' +
        ('"' + r.replace(/\*$/, "/*") + '" because the `*` character must ') +
        "always follow a `/` in the pattern. To get rid of this warning, " +
        ('please change the route path to "' + r.replace(/\*$/, "/*") + '".'),
    ));
  let c = [],
    d =
      "^" +
      r
        .replace(/\/*\*?$/, "")
        .replace(/^\/*/, "/")
        .replace(/[\\.*+^${}|()[\]]/g, "\\$&")
        .replace(
          /\/:([\w-]+)(\?)?/g,
          (x, h, v) => (
            c.push({ paramName: h, isOptional: v != null }),
            v ? "/?([^\\/]+)?" : "/([^\\/]+)"
          ),
        );
  return (
    r.endsWith("*")
      ? (c.push({ paramName: "*" }),
        (d += r === "*" || r === "/*" ? "(.*)$" : "(?:\\/(.+)|\\/*)$"))
      : a
        ? (d += "\\/*$")
        : r !== "" && r !== "/" && (d += "(?:(?=\\/|$))"),
    [new RegExp(d, s ? void 0 : "i"), c]
  );
}
function qu(r) {
  try {
    return r
      .split("/")
      .map((s) => decodeURIComponent(s).replace(/\//g, "%2F"))
      .join("/");
  } catch (s) {
    return (
      Da(
        !1,
        'The URL path "' +
          r +
          '" could not be decoded because it is is a malformed URL segment. This is probably due to a bad percent ' +
          ("encoding (" + s + ")."),
      ),
      r
    );
  }
}
function Ha(r, s) {
  if (s === "/") return r;
  if (!r.toLowerCase().startsWith(s.toLowerCase())) return null;
  let a = s.endsWith("/") ? s.length - 1 : s.length,
    c = r.charAt(a);
  return c && c !== "/" ? null : r.slice(a) || "/";
}
function e6(r, s) {
  s === void 0 && (s = "/");
  let {
    pathname: a,
    search: c = "",
    hash: d = "",
  } = typeof r == "string" ? sr(r) : r;
  return {
    pathname: a ? (a.startsWith("/") ? a : t6(a, s)) : s,
    search: s6(c),
    hash: o6(d),
  };
}
function t6(r, s) {
  let a = s.replace(/\/+$/, "").split("/");
  return (
    r.split("/").forEach((d) => {
      d === ".." ? a.length > 1 && a.pop() : d !== "." && a.push(d);
    }),
    a.length > 1 ? a.join("/") : "/"
  );
}
function N0(r, s, a, c) {
  return (
    "Cannot include a '" +
    r +
    "' character in a manually specified " +
    ("`to." +
      s +
      "` field [" +
      JSON.stringify(c) +
      "].  Please separate it out to the ") +
    ("`to." + a + "` field. Alternatively you may provide the full path as ") +
    'a string in <Link to="..."> and the router will parse it for you.'
  );
}
function n6(r) {
  return r.filter(
    (s, a) => a === 0 || (s.route.path && s.route.path.length > 0),
  );
}
function r6(r, s) {
  let a = n6(r);
  return s
    ? a.map((c, d) => (d === a.length - 1 ? c.pathname : c.pathnameBase))
    : a.map((c) => c.pathnameBase);
}
function l6(r, s, a, c) {
  c === void 0 && (c = !1);
  let d;
  typeof r == "string"
    ? (d = sr(r))
    : ((d = Qr({}, r)),
      be(
        !d.pathname || !d.pathname.includes("?"),
        N0("?", "pathname", "search", d),
      ),
      be(
        !d.pathname || !d.pathname.includes("#"),
        N0("#", "pathname", "hash", d),
      ),
      be(!d.search || !d.search.includes("#"), N0("#", "search", "hash", d)));
  let m = r === "" || d.pathname === "",
    x = m ? "/" : d.pathname,
    h;
  if (x == null) h = a;
  else {
    let j = s.length - 1;
    if (!c && x.startsWith("..")) {
      let b = x.split("/");
      for (; b[0] === ".."; ) (b.shift(), (j -= 1));
      d.pathname = b.join("/");
    }
    h = j >= 0 ? s[j] : "/";
  }
  let v = e6(d, h),
    y = x && x !== "/" && x.endsWith("/"),
    M = (m || x === ".") && a.endsWith("/");
  return (!v.pathname.endsWith("/") && (y || M) && (v.pathname += "/"), v);
}
const Sn = (r) => r.join("/").replace(/\/\/+/g, "/"),
  i6 = (r) => r.replace(/\/+$/, "").replace(/^\/*/, "/"),
  s6 = (r) => (!r || r === "?" ? "" : r.startsWith("?") ? r : "?" + r),
  o6 = (r) => (!r || r === "#" ? "" : r.startsWith("#") ? r : "#" + r);
function a6(r) {
  return (
    r != null &&
    typeof r.status == "number" &&
    typeof r.statusText == "string" &&
    typeof r.internal == "boolean" &&
    "data" in r
  );
}
const Va = ["post", "put", "patch", "delete"];
new Set(Va);
const u6 = ["get", ...Va];
new Set(u6);
/**
 * React Router v6.30.0
 *
 * Copyright (c) Remix Software Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.md file in the root directory of this source tree.
 *
 * @license MIT
 */ function Kr() {
  return (
    (Kr = Object.assign
      ? Object.assign.bind()
      : function (r) {
          for (var s = 1; s < arguments.length; s++) {
            var a = arguments[s];
            for (var c in a)
              Object.prototype.hasOwnProperty.call(a, c) && (r[c] = a[c]);
          }
          return r;
        }),
    Kr.apply(this, arguments)
  );
}
const U0 = p.createContext(null),
  c6 = p.createContext(null),
  gl = p.createContext(null),
  wl = p.createContext(null),
  or = p.createContext({ outlet: null, matches: [], isDataRoute: !1 }),
  za = p.createContext(null);
function yl() {
  return p.useContext(wl) != null;
}
function Z0() {
  return (yl() || be(!1), p.useContext(wl).location);
}
function Ua(r) {
  p.useContext(gl).static || p.useLayoutEffect(r);
}
function Za() {
  let { isDataRoute: r } = p.useContext(or);
  return r ? N6() : d6();
}
function d6() {
  yl() || be(!1);
  let r = p.useContext(U0),
    { basename: s, future: a, navigator: c } = p.useContext(gl),
    { matches: d } = p.useContext(or),
    { pathname: m } = Z0(),
    x = JSON.stringify(r6(d, a.v7_relativeSplatPath)),
    h = p.useRef(!1);
  return (
    Ua(() => {
      h.current = !0;
    }),
    p.useCallback(
      function (y, M) {
        if ((M === void 0 && (M = {}), !h.current)) return;
        if (typeof y == "number") {
          c.go(y);
          return;
        }
        let j = l6(y, JSON.parse(x), m, M.relative === "path");
        (r == null &&
          s !== "/" &&
          (j.pathname = j.pathname === "/" ? s : Sn([s, j.pathname])),
          (M.replace ? c.replace : c.push)(j, M.state, M));
      },
      [s, c, x, m, r],
    )
  );
}
function f6(r, s) {
  return m6(r, s);
}
function m6(r, s, a, c) {
  yl() || be(!1);
  let { navigator: d, static: m } = p.useContext(gl),
    { matches: x } = p.useContext(or),
    h = x[x.length - 1],
    v = h ? h.params : {};
  h && h.pathname;
  let y = h ? h.pathnameBase : "/";
  h && h.route;
  let M = Z0(),
    j;
  if (s) {
    var b;
    let P = typeof s == "string" ? sr(s) : s;
    (y === "/" || ((b = P.pathname) != null && b.startsWith(y)) || be(!1),
      (j = P));
  } else j = M;
  let O = j.pathname || "/",
    H = O;
  if (y !== "/") {
    let P = y.replace(/^\//, "").split("/");
    H = "/" + O.replace(/^\//, "").split("/").slice(P.length).join("/");
  }
  let N = Bu(r, { pathname: H }),
    k = v6(
      N &&
        N.map((P) =>
          Object.assign({}, P, {
            params: Object.assign({}, v, P.params),
            pathname: Sn([
              y,
              d.encodeLocation
                ? d.encodeLocation(P.pathname).pathname
                : P.pathname,
            ]),
            pathnameBase:
              P.pathnameBase === "/"
                ? y
                : Sn([
                    y,
                    d.encodeLocation
                      ? d.encodeLocation(P.pathnameBase).pathname
                      : P.pathnameBase,
                  ]),
          }),
        ),
      x,
      a,
      c,
    );
  return s && k
    ? p.createElement(
        wl.Provider,
        {
          value: {
            location: Kr(
              {
                pathname: "/",
                search: "",
                hash: "",
                state: null,
                key: "default",
              },
              j,
            ),
            navigationType: cn.Pop,
          },
        },
        k,
      )
    : k;
}
function h6() {
  let r = j6(),
    s = a6(r)
      ? r.status + " " + r.statusText
      : r instanceof Error
        ? r.message
        : JSON.stringify(r),
    a = r instanceof Error ? r.stack : null,
    d = { padding: "0.5rem", backgroundColor: "rgba(200,200,200, 0.5)" };
  return p.createElement(
    p.Fragment,
    null,
    p.createElement("h2", null, "Unexpected Application Error!"),
    p.createElement("h3", { style: { fontStyle: "italic" } }, s),
    a ? p.createElement("pre", { style: d }, a) : null,
    null,
  );
}
const p6 = p.createElement(h6, null);
class x6 extends p.Component {
  constructor(s) {
    (super(s),
      (this.state = {
        location: s.location,
        revalidation: s.revalidation,
        error: s.error,
      }));
  }
  static getDerivedStateFromError(s) {
    return { error: s };
  }
  static getDerivedStateFromProps(s, a) {
    return a.location !== s.location ||
      (a.revalidation !== "idle" && s.revalidation === "idle")
      ? { error: s.error, location: s.location, revalidation: s.revalidation }
      : {
          error: s.error !== void 0 ? s.error : a.error,
          location: a.location,
          revalidation: s.revalidation || a.revalidation,
        };
  }
  componentDidCatch(s, a) {
    console.error(
      "React Router caught the following error during render",
      s,
      a,
    );
  }
  render() {
    return this.state.error !== void 0
      ? p.createElement(
          or.Provider,
          { value: this.props.routeContext },
          p.createElement(za.Provider, {
            value: this.state.error,
            children: this.props.component,
          }),
        )
      : this.props.children;
  }
}
function C6(r) {
  let { routeContext: s, match: a, children: c } = r,
    d = p.useContext(U0);
  return (
    d &&
      d.static &&
      d.staticContext &&
      (a.route.errorElement || a.route.ErrorBoundary) &&
      (d.staticContext._deepestRenderedBoundaryId = a.route.id),
    p.createElement(or.Provider, { value: s }, c)
  );
}
function v6(r, s, a, c) {
  var d;
  if (
    (s === void 0 && (s = []),
    a === void 0 && (a = null),
    c === void 0 && (c = null),
    r == null)
  ) {
    var m;
    if (!a) return null;
    if (a.errors) r = a.matches;
    else if (
      (m = c) != null &&
      m.v7_partialHydration &&
      s.length === 0 &&
      !a.initialized &&
      a.matches.length > 0
    )
      r = a.matches;
    else return null;
  }
  let x = r,
    h = (d = a) == null ? void 0 : d.errors;
  if (h != null) {
    let M = x.findIndex(
      (j) => j.route.id && (h == null ? void 0 : h[j.route.id]) !== void 0,
    );
    (M >= 0 || be(!1), (x = x.slice(0, Math.min(x.length, M + 1))));
  }
  let v = !1,
    y = -1;
  if (a && c && c.v7_partialHydration)
    for (let M = 0; M < x.length; M++) {
      let j = x[M];
      if (
        ((j.route.HydrateFallback || j.route.hydrateFallbackElement) && (y = M),
        j.route.id)
      ) {
        let { loaderData: b, errors: O } = a,
          H =
            j.route.loader &&
            b[j.route.id] === void 0 &&
            (!O || O[j.route.id] === void 0);
        if (j.route.lazy || H) {
          ((v = !0), y >= 0 ? (x = x.slice(0, y + 1)) : (x = [x[0]]));
          break;
        }
      }
    }
  return x.reduceRight((M, j, b) => {
    let O,
      H = !1,
      N = null,
      k = null;
    a &&
      ((O = h && j.route.id ? h[j.route.id] : void 0),
      (N = j.route.errorElement || p6),
      v &&
        (y < 0 && b === 0
          ? (L6("route-fallback"), (H = !0), (k = null))
          : y === b &&
            ((H = !0), (k = j.route.hydrateFallbackElement || null))));
    let P = s.concat(x.slice(0, b + 1)),
      T = () => {
        let V;
        return (
          O
            ? (V = N)
            : H
              ? (V = k)
              : j.route.Component
                ? (V = p.createElement(j.route.Component, null))
                : j.route.element
                  ? (V = j.route.element)
                  : (V = M),
          p.createElement(C6, {
            match: j,
            routeContext: { outlet: M, matches: P, isDataRoute: a != null },
            children: V,
          })
        );
      };
    return a && (j.route.ErrorBoundary || j.route.errorElement || b === 0)
      ? p.createElement(x6, {
          location: a.location,
          revalidation: a.revalidation,
          component: N,
          error: O,
          children: T(),
          routeContext: { outlet: null, matches: P, isDataRoute: !0 },
        })
      : T();
  }, null);
}
var Wa = (function (r) {
    return (
      (r.UseBlocker = "useBlocker"),
      (r.UseRevalidator = "useRevalidator"),
      (r.UseNavigateStable = "useNavigate"),
      r
    );
  })(Wa || {}),
  $a = (function (r) {
    return (
      (r.UseBlocker = "useBlocker"),
      (r.UseLoaderData = "useLoaderData"),
      (r.UseActionData = "useActionData"),
      (r.UseRouteError = "useRouteError"),
      (r.UseNavigation = "useNavigation"),
      (r.UseRouteLoaderData = "useRouteLoaderData"),
      (r.UseMatches = "useMatches"),
      (r.UseRevalidator = "useRevalidator"),
      (r.UseNavigateStable = "useNavigate"),
      (r.UseRouteId = "useRouteId"),
      r
    );
  })($a || {});
function g6(r) {
  let s = p.useContext(U0);
  return (s || be(!1), s);
}
function w6(r) {
  let s = p.useContext(c6);
  return (s || be(!1), s);
}
function y6(r) {
  let s = p.useContext(or);
  return (s || be(!1), s);
}
function Ga(r) {
  let s = y6(),
    a = s.matches[s.matches.length - 1];
  return (a.route.id || be(!1), a.route.id);
}
function j6() {
  var r;
  let s = p.useContext(za),
    a = w6(),
    c = Ga();
  return s !== void 0 ? s : (r = a.errors) == null ? void 0 : r[c];
}
function N6() {
  let { router: r } = g6(Wa.UseNavigateStable),
    s = Ga($a.UseNavigateStable),
    a = p.useRef(!1);
  return (
    Ua(() => {
      a.current = !0;
    }),
    p.useCallback(
      function (d, m) {
        (m === void 0 && (m = {}),
          a.current &&
            (typeof d == "number"
              ? r.navigate(d)
              : r.navigate(d, Kr({ fromRouteId: s }, m))));
      },
      [r, s],
    )
  );
}
const ia = {};
function L6(r, s, a) {
  ia[r] || (ia[r] = !0);
}
function E6(r, s) {
  (r == null || r.v7_startTransition, r == null || r.v7_relativeSplatPath);
}
function Vt(r) {
  be(!1);
}
function S6(r) {
  let {
    basename: s = "/",
    children: a = null,
    location: c,
    navigationType: d = cn.Pop,
    navigator: m,
    static: x = !1,
    future: h,
  } = r;
  yl() && be(!1);
  let v = s.replace(/^\/*/, "/"),
    y = p.useMemo(
      () => ({
        basename: v,
        navigator: m,
        static: x,
        future: Kr({ v7_relativeSplatPath: !1 }, h),
      }),
      [v, h, m, x],
    );
  typeof c == "string" && (c = sr(c));
  let {
      pathname: M = "/",
      search: j = "",
      hash: b = "",
      state: O = null,
      key: H = "default",
    } = c,
    N = p.useMemo(() => {
      let k = Ha(M, v);
      return k == null
        ? null
        : {
            location: { pathname: k, search: j, hash: b, state: O, key: H },
            navigationType: d,
          };
    }, [v, M, j, b, O, H, d]);
  return N == null
    ? null
    : p.createElement(
        gl.Provider,
        { value: y },
        p.createElement(wl.Provider, { children: a, value: N }),
      );
}
function k6(r) {
  let { children: s, location: a } = r;
  return f6(A0(s), a);
}
new Promise(() => {});
function A0(r, s) {
  s === void 0 && (s = []);
  let a = [];
  return (
    p.Children.forEach(r, (c, d) => {
      if (!p.isValidElement(c)) return;
      let m = [...s, d];
      if (c.type === p.Fragment) {
        a.push.apply(a, A0(c.props.children, m));
        return;
      }
      (c.type !== Vt && be(!1), !c.props.index || !c.props.children || be(!1));
      let x = {
        id: c.props.id || m.join("-"),
        caseSensitive: c.props.caseSensitive,
        element: c.props.element,
        Component: c.props.Component,
        index: c.props.index,
        path: c.props.path,
        loader: c.props.loader,
        action: c.props.action,
        errorElement: c.props.errorElement,
        ErrorBoundary: c.props.ErrorBoundary,
        hasErrorBoundary:
          c.props.ErrorBoundary != null || c.props.errorElement != null,
        shouldRevalidate: c.props.shouldRevalidate,
        handle: c.props.handle,
        lazy: c.props.lazy,
      };
      (c.props.children && (x.children = A0(c.props.children, m)), a.push(x));
    }),
    a
  );
}
/**
 * React Router DOM v6.30.0
 *
 * Copyright (c) Remix Software Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.md file in the root directory of this source tree.
 *
 * @license MIT
 */ const R6 = "6";
try {
  window.__reactRouterVersion = R6;
} catch {}
const M6 = "startTransition",
  sa = _a[M6];
function b6(r) {
  let { basename: s, children: a, future: c, window: d } = r,
    m = p.useRef();
  m.current == null && (m.current = Du({ window: d, v5Compat: !0 }));
  let x = m.current,
    [h, v] = p.useState({ action: x.action, location: x.location }),
    { v7_startTransition: y } = c || {},
    M = p.useCallback(
      (j) => {
        y && sa ? sa(() => v(j)) : v(j);
      },
      [v, y],
    );
  return (
    p.useLayoutEffect(() => x.listen(M), [x, M]),
    p.useEffect(() => E6(c), [c]),
    p.createElement(S6, {
      basename: s,
      children: a,
      location: h.location,
      navigationType: h.action,
      navigator: x,
      future: c,
    })
  );
}
var oa;
(function (r) {
  ((r.UseScrollRestoration = "useScrollRestoration"),
    (r.UseSubmit = "useSubmit"),
    (r.UseSubmitFetcher = "useSubmitFetcher"),
    (r.UseFetcher = "useFetcher"),
    (r.useViewTransitionState = "useViewTransitionState"));
})(oa || (oa = {}));
var aa;
(function (r) {
  ((r.UseFetcher = "useFetcher"),
    (r.UseFetchers = "useFetchers"),
    (r.UseScrollRestoration = "useScrollRestoration"));
})(aa || (aa = {}));
const ml = () => !window.invokeNative,
  P6 = () => {},
  kn = (r, s) => {
    const a = p.useRef(P6);
    (p.useEffect(() => {
      a.current = s;
    }, [s]),
      p.useEffect(() => {
        const c = (d) => {
          const { action: m, data: x } = (d == null ? void 0 : d.data) ?? {};
          a != null && a.current && m === r && a.current(x);
        };
        return (
          window.addEventListener("message", c),
          () => window.removeEventListener("message", c)
        );
      }, [r]));
  };
async function se(r, s, a) {
  const c = { method: "post", body: JSON.stringify(s) };
  if (ml() && a) return a;
  const d = window.GetParentResourceName
    ? window.GetParentResourceName()
    : "nui-frame-app";
  return await (await fetch(`https://${d}/${r}`, c)).json();
}
const O6 = {},
  ua = (r) => {
    let s;
    const a = new Set(),
      c = (M, j) => {
        const b = typeof M == "function" ? M(s) : M;
        if (!Object.is(b, s)) {
          const O = s;
          ((s =
            (j ?? (typeof b != "object" || b === null))
              ? b
              : Object.assign({}, s, b)),
            a.forEach((H) => H(s, O)));
        }
      },
      d = () => s,
      v = {
        setState: c,
        getState: d,
        getInitialState: () => y,
        subscribe: (M) => (a.add(M), () => a.delete(M)),
        destroy: () => {
          ((O6 ? "production" : void 0) !== "production" &&
            console.warn(
              "[DEPRECATED] The `destroy` method will be unsupported in a future version. Instead use unsubscribe function returned by subscribe. Everything will be garbage-collected if store is garbage-collected.",
            ),
            a.clear());
        },
      },
      y = (s = r(c, d, v));
    return v;
  },
  _6 = (r) => (r ? ua(r) : ua);
var L0 = { exports: {} },
  E0 = {},
  S0 = { exports: {} },
  k0 = {};
/**
 * @license React
 * use-sync-external-store-shim.production.js
 *
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var ca;
function F6() {
  if (ca) return k0;
  ca = 1;
  var r = Yr();
  function s(j, b) {
    return (j === b && (j !== 0 || 1 / j === 1 / b)) || (j !== j && b !== b);
  }
  var a = typeof Object.is == "function" ? Object.is : s,
    c = r.useState,
    d = r.useEffect,
    m = r.useLayoutEffect,
    x = r.useDebugValue;
  function h(j, b) {
    var O = b(),
      H = c({ inst: { value: O, getSnapshot: b } }),
      N = H[0].inst,
      k = H[1];
    return (
      m(
        function () {
          ((N.value = O), (N.getSnapshot = b), v(N) && k({ inst: N }));
        },
        [j, O, b],
      ),
      d(
        function () {
          return (
            v(N) && k({ inst: N }),
            j(function () {
              v(N) && k({ inst: N });
            })
          );
        },
        [j],
      ),
      x(O),
      O
    );
  }
  function v(j) {
    var b = j.getSnapshot;
    j = j.value;
    try {
      var O = b();
      return !a(j, O);
    } catch {
      return !0;
    }
  }
  function y(j, b) {
    return b();
  }
  var M =
    typeof window > "u" ||
    typeof window.document > "u" ||
    typeof window.document.createElement > "u"
      ? y
      : h;
  return (
    (k0.useSyncExternalStore =
      r.useSyncExternalStore !== void 0 ? r.useSyncExternalStore : M),
    k0
  );
}
var da;
function I6() {
  return (da || ((da = 1), (S0.exports = F6())), S0.exports);
}
/**
 * @license React
 * use-sync-external-store-shim/with-selector.production.js
 *
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */ var fa;
function D6() {
  if (fa) return E0;
  fa = 1;
  var r = Yr(),
    s = I6();
  function a(y, M) {
    return (y === M && (y !== 0 || 1 / y === 1 / M)) || (y !== y && M !== M);
  }
  var c = typeof Object.is == "function" ? Object.is : a,
    d = s.useSyncExternalStore,
    m = r.useRef,
    x = r.useEffect,
    h = r.useMemo,
    v = r.useDebugValue;
  return (
    (E0.useSyncExternalStoreWithSelector = function (y, M, j, b, O) {
      var H = m(null);
      if (H.current === null) {
        var N = { hasValue: !1, value: null };
        H.current = N;
      } else N = H.current;
      H = h(
        function () {
          function P(K) {
            if (!T) {
              if (((T = !0), (V = K), (K = b(K)), O !== void 0 && N.hasValue)) {
                var Y = N.value;
                if (O(Y, K)) return (Z = Y);
              }
              return (Z = K);
            }
            if (((Y = Z), c(V, K))) return Y;
            var de = b(K);
            return O !== void 0 && O(Y, de)
              ? ((V = K), Y)
              : ((V = K), (Z = de));
          }
          var T = !1,
            V,
            Z,
            ee = j === void 0 ? null : j;
          return [
            function () {
              return P(M());
            },
            ee === null
              ? void 0
              : function () {
                  return P(ee());
                },
          ];
        },
        [M, j, b, O],
      );
      var k = d(y, H[0], H[1]);
      return (
        x(
          function () {
            ((N.hasValue = !0), (N.value = k));
          },
          [k],
        ),
        v(k),
        k
      );
    }),
    E0
  );
}
var ma;
function T6() {
  return (ma || ((ma = 1), (L0.exports = D6())), L0.exports);
}
var A6 = T6();
const B6 = vl(A6),
  W0 = {},
  { useDebugValue: H6 } = z0,
  { useSyncExternalStoreWithSelector: V6 } = B6;
let ha = !1;
const z6 = (r) => r;
function U6(r, s = z6, a) {
  (W0 ? "production" : void 0) !== "production" &&
    a &&
    !ha &&
    (console.warn(
      "[DEPRECATED] Use `createWithEqualityFn` instead of `create` or use `useStoreWithEqualityFn` instead of `useStore`. They can be imported from 'zustand/traditional'. https://github.com/pmndrs/zustand/discussions/1937",
    ),
    (ha = !0));
  const c = V6(
    r.subscribe,
    r.getState,
    r.getServerState || r.getInitialState,
    s,
    a,
  );
  return (H6(c), c);
}
const pa = (r) => {
    (W0 ? "production" : void 0) !== "production" &&
      typeof r != "function" &&
      console.warn(
        "[DEPRECATED] Passing a vanilla store will be unsupported in a future version. Instead use `import { useStore } from 'zustand'`.",
      );
    const s = typeof r == "function" ? _6(r) : r,
      a = (c, d) => U6(s, c, d);
    return (Object.assign(a, s), a);
  },
  Z6 = (r) => (r ? pa(r) : pa);
var Qa = (r) => (
  (W0 ? "production" : void 0) !== "production" &&
    console.warn(
      "[DEPRECATED] Default export is deprecated. Instead use `import { create } from 'zustand'`.",
    ),
  Z6(r)
);
const Ze = Qa((r) => ({
  radio: 1,
  setRadio: (s) => r({ radio: s ?? 1 }),
  preset: { male: "", female: "" },
  setPreset: (s) =>
    r({
      preset: {
        male: (s == null ? void 0 : s.male) ?? "",
        female: (s == null ? void 0 : s.female) ?? "",
      },
    }),
  openedModal: !1,
  setOpenedModal: (s) => r({ openedModal: s ?? !1 }),
  openedPermissionsModal: !1,
  setOpenedPermissionsModal: (s) => r({ openedPermissionsModal: s ?? !1 }),
  openedPartnerModal: !1,
  setOpenedPartnerModal: (s) => r({ openedPartnerModal: s ?? !1 }),
  partners: [],
  setPartners: (s) => r({ partners: s ?? [] }),
  openedEditGoal: !1,
  setOpenedEditGoal: (s) => r({ openedEditGoal: s ?? !1 }),
  goals: { prize: "", my: [], faction: [], members: [] },
  setGoals: (s) =>
    r({
      goals: {
        prize: (s == null ? void 0 : s.prize) ?? "",
        my: Array.isArray(s == null ? void 0 : s.my) ? s.my : [],
        faction: Array.isArray(s == null ? void 0 : s.faction) ? s.faction : [],
        members: Array.isArray(s == null ? void 0 : s.members) ? s.members : [],
      },
    }),
  openedNewGoal: !1,
  setOpenedNewGoal: (s) => r({ openedNewGoal: s ?? !1 }),
  typeNewGoal: "",
  setTypeNewGoal: (s) => r({ typeNewGoal: s ?? "" }),
  contractModal: !1,
  setOpenedContractModal: (s) => r({ contractModal: s ?? !1 }),
  user_id: 0,
  setUserId: (s) => r({ user_id: s ?? 0 }),
  setCanWarn: (s) => r({ canWarn: s ?? !1 }),
  canWarn: !1,
  avatar: "",
  setAvatar: (s) => r({ avatar: s ?? "" }),
  setWarnings: (s) => r({ warnings: Array.isArray(s) ? s : [] }),
  warnings: [],
  orgBalance: 0,
  setOrgBalance: (s) => r({ orgBalance: s ?? 0 }),
  playerBalance: 0,
  setPlayerBalance: (s) => r({ playerBalance: s ?? 0 }),
  name: "",
  setName: (s) => r({ name: s ?? "" }),
  setWarningModalVisible: (s) => r({ warningModalVisible: s ?? !1 }),
  warningModalVisible: !1,
  logo: "",
  setLogo: (s) => r({ logo: s ?? "" }),
  leader: "",
  members: 0,
  membersOnline: 0,
  goalReward: 0,
  setGoalReward: (s) => r({ goalReward: s ?? 0 }),
  setMembers: (s) => r({ members: s ?? 0 }),
  setMembersOnline: (s) => r({ membersOnline: s ?? 0 }),
  setleader: (s) => r({ leader: s ?? "" }),
  orgName: "",
  setOrgName: (s) => r({ orgName: s ?? "" }),
  permissionsModalVisible: !1,
  setPermissionsModalVisible: (s) => r({ permissionsModalVisible: s ?? !1 }),
  roleEdit: "",
  setRoleEdit: (s) => r({ roleEdit: s ?? "" }),
  setPermissions: (s) =>
    r({
      permissions: {
        name: (s == null ? void 0 : s.name) ?? !1,
        promote: (s == null ? void 0 : s.promote) ?? !1,
        demote: (s == null ? void 0 : s.demote) ?? !1,
        dismiss: (s == null ? void 0 : s.dismiss) ?? !1,
        withdraw: (s == null ? void 0 : s.withdraw) ?? !1,
        deposit: (s == null ? void 0 : s.deposit) ?? !1,
        message: (s == null ? void 0 : s.message) ?? !1,
        alerts: (s == null ? void 0 : s.alerts) ?? !1,
        invite: (s == null ? void 0 : s.invite) ?? !1,
        leader: (s == null ? void 0 : s.leader) ?? !1,
        chat: (s == null ? void 0 : s.chat) ?? !1,
      },
    }),
  permissions: {
    name: !1,
    promote: !1,
    demote: !1,
    dismiss: !1,
    withdraw: !1,
    deposit: !1,
    message: !1,
    alerts: !1,
    invite: !1,
    leader: !1,
    chat: !1,
  },
  roles: [],
  setRoles: (s) => r({ roles: Array.isArray(s) ? s : [] }),
  discord: "",
  setDiscord: (s) => r({ discord: s ?? "" }),
  serverIcon: "",
  setServerIcon: (s) => r({ serverIcon: s ?? "" }),
  nextPayment: !1,
  setNextPayment: (s) => r({ nextPayment: s ?? !1 }),
  salary: 0,
  setSalary: (s) => r({ salary: s ?? 0 }),
  store: "",
  setStore: (s) => r({ store: s ?? "" }),
  factionVip: "",
  setFactionVip: (s) => r({ factionVip: s ?? "" }),
  nextPaymentMax: 0,
  setNextPaymentMax: (s) => r({ nextPaymentMax: s ?? 0 }),
  setGoalModalVisible: (s) => r({ goalModalVisible: s ?? !1 }),
  goalModalVisible: !1,
  setConfigModalVisible: (s) => r({ configModalVisible: s ?? !1 }),
  configModalVisible: !1,
  update: (s) => r({ ...s }),
  max: 0,
  setMax: (s) => r({ max: s ?? 0 }),
  current: 0,
  setCurrent: (s) => r({ current: s ?? 0 }),
  title: "",
  setTitle: (s) => r({ title: s ?? "" }),
  description: "",
  setDescription: (s) => r({ description: s ?? "" }),
  index: null,
  setIndex: (s) => r({ index: s ?? null }),
  painelType: "legal",
  setPainelType: (s) => r({ painelType: s ?? "legal" }),
  maxMembers: 0,
  setMaxMembers: (s) => r({ maxMembers: s ?? 0 }),
}));
Qa((r) => ({
  modal: {
    time: 0,
    title: "",
    description: "",
    placeholder: "",
    save: (s) => {},
  },
  setModal: (s) =>
    r({
      modal: {
        time: (s == null ? void 0 : s.time) ?? 0,
        title: (s == null ? void 0 : s.title) ?? "",
        description: (s == null ? void 0 : s.description) ?? "",
        placeholder: (s == null ? void 0 : s.placeholder) ?? "",
        save: (s == null ? void 0 : s.save) ?? ((a) => {}),
      },
    }),
}));
const W6 = p.createContext(null),
  $6 = ({ children: r }) => {
    const s = Za(),
      [a, c] = p.useState(ml()),
      {
        setPainelType: d,
        setPreset: m,
        setRadio: x,
        setWarnings: h,
        setUserId: v,
        setMaxMembers: y,
        setAvatar: M,
        setOrgBalance: j,
        setWarningModalVisible: b,
        setConfigModalVisible: O,
        setGoalModalVisible: H,
        setServerIcon: N,
        setName: k,
        setPlayerBalance: P,
        setCanWarn: T,
        setDiscord: V,
        setLogo: Z,
        setMembers: ee,
        setNextPaymentMax: K,
        setStore: Y,
        setMembersOnline: de,
        setleader: Pe,
        setOrgName: Ae,
        setPermissions: st,
        setRoles: Oe,
        setNextPayment: Le,
        setSalary: et,
        setGoalReward: ot,
        setFactionVip: Be,
      } = Ze();
    function xe() {
      se(
        "GetPainelInfos",
        {},
        {
          radio: 1336,
          user_id: 1337,
          preset: { male: "aa", female: "bbb" },
          avatar: "https://i.imgur.com/exJslvp.png",
          orgBalance: 25e3,
          name: "ruan jkz",
          leader: "Mirtin",
          serverIcon: "https://i.imgur.com/exJslvp.png",
          orgName: "Turquia",
          members: 25,
          membersOnline: 10,
          salary: 5e3,
          nextPayment: 4e3,
          nextPaymentMax: 2e3,
          goalReward: 1e3,
          store: "https://discord.gg/ruanjkz",
          factionVip: "PRATA",
          playerBalance: 1e5,
          type: "ilegal",
          roles: [
            { prefix: "Membro", group: "Membro", nivel: 2, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
            { prefix: "Líder", group: "Líder", nivel: 1, members: 23 },
          ],
          maxMembers: 50,
          discord: "https://discord.gg/ruanjkz",
          permissions: {
            name: !0,
            promote: !0,
            demote: !0,
            dismiss: !0,
            withdraw: !0,
            deposit: !1,
            message: !0,
            alerts: !0,
            invite: !0,
            chat: !0,
            leader: !0,
          },
          logo: "",
          canWarn: !0,
          warnings: [
            {
              author: "Ruan",
              author_id: 1337,
              message:
                "Recrutamento para a Polícia da Baixada RJ está oficialmente aberto! Interessados devem comparecer ao Departamento de Polícia 2 (DP2) para maiores informações e formalizar sua candidatura. Não se esqueçam de verificar o fardamento e o manual de conduta, que estão disponíveis no e-mail, na aba destinada ao conteúdo da corporação",
              author_avatar: "https://i.imgur.com/exJslvp.png",
              date: "15/03/2024",
            },
            {
              author: "Ruan",
              author_id: 1337,
              author_avatar: "https://i.imgur.com/exJslvp.png",
              message:
                "Simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industrys standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries.",
              date: "15/03/2024",
            },
            {
              author: "Ruan",
              author_id: 1337,
              author_avatar: "https://i.imgur.com/exJslvp.png",
              message:
                "Simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industrys standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries.",
              date: "15/03/2024",
            },
            {
              author: "Ruan",
              author_id: 1337,
              author_avatar: "https://i.imgur.com/exJslvp.png",
              message:
                "Simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industrys standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries.",
              date: "15/03/2024",
            },
            {
              author: "Ruan",
              author_id: 1337,
              author_avatar: "https://i.imgur.com/exJslvp.png",
              message:
                "Simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industrys standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries.",
              date: "15/03/2024",
            },
          ],
        },
      ).then((F) => {
        (x(F.radio),
          M(F.avatar),
          v(F.user_id),
          j(F.orgBalance),
          k(F.name),
          Z(F.logo),
          T(F.canWarn),
          P(F.playerBalance),
          st(F.permissions),
          Pe(F.leader),
          ee(F.members),
          de(F.membersOnline),
          h(F.warnings),
          Ae(F.orgName),
          Oe(F.roles),
          N(F.serverIcon),
          V(F.discord),
          Le(F.nextPayment),
          et(F.salary),
          Y(F.store),
          K(F.nextPaymentMax),
          ot(F.goalReward),
          m(F.preset),
          y(F.maxMembers),
          d(F.type),
          Be(F.factionVip));
      });
    }
    return (
      p.useEffect(() => {
        ml() && xe();
      }, []),
      kn("open", () => {
        (c(!0), s("/"), H(!1), b(!1), O(!1), xe());
      }),
      kn("UpdatePermissions", st),
      kn("close", () => c(!1)),
      p.useEffect(() => {
        if (!a) return;
        const F = (q) => {
          if (q.code === "Escape") {
            if (ml()) return c(!1);
            (c(!1), se("close"));
          }
        };
        return (
          window.addEventListener("keydown", F),
          () => window.removeEventListener("keydown", F)
        );
      }, [a]),
      i.jsx(W6.Provider, { value: {}, children: a && r })
    );
  };
function Ka(r) {
  var s,
    a,
    c = "";
  if (typeof r == "string" || typeof r == "number") c += r;
  else if (typeof r == "object")
    if (Array.isArray(r)) {
      var d = r.length;
      for (s = 0; s < d; s++)
        r[s] && (a = Ka(r[s])) && (c && (c += " "), (c += a));
    } else for (a in r) r[a] && (c && (c += " "), (c += a));
  return c;
}
function ne() {
  for (var r, s, a = 0, c = "", d = arguments.length; a < d; a++)
    (r = arguments[a]) && (s = Ka(r)) && (c && (c += " "), (c += s));
  return c;
}
function dn(r, s, { checkForDefaultPrevented: a = !0 } = {}) {
  return function (d) {
    if ((r == null || r(d), a === !1 || !d.defaultPrevented))
      return s == null ? void 0 : s(d);
  };
}
function xa(r, s) {
  if (typeof r == "function") return r(s);
  r != null && (r.current = s);
}
function Ya(...r) {
  return (s) => {
    let a = !1;
    const c = r.map((d) => {
      const m = xa(d, s);
      return (!a && typeof m == "function" && (a = !0), m);
    });
    if (a)
      return () => {
        for (let d = 0; d < c.length; d++) {
          const m = c[d];
          typeof m == "function" ? m() : xa(r[d], null);
        }
      };
  };
}
function bn(...r) {
  return p.useCallback(Ya(...r), r);
}
function G6(r, s) {
  const a = p.createContext(s),
    c = (m) => {
      const { children: x, ...h } = m,
        v = p.useMemo(() => h, Object.values(h));
      return i.jsx(a.Provider, { value: v, children: x });
    };
  c.displayName = r + "Provider";
  function d(m) {
    const x = p.useContext(a);
    if (x) return x;
    if (s !== void 0) return s;
    throw new Error(`\`${m}\` must be used within \`${r}\``);
  }
  return [c, d];
}
function Q6(r, s = []) {
  let a = [];
  function c(m, x) {
    const h = p.createContext(x),
      v = a.length;
    a = [...a, x];
    const y = (j) => {
      var P;
      const { scope: b, children: O, ...H } = j,
        N = ((P = b == null ? void 0 : b[r]) == null ? void 0 : P[v]) || h,
        k = p.useMemo(() => H, Object.values(H));
      return i.jsx(N.Provider, { value: k, children: O });
    };
    y.displayName = m + "Provider";
    function M(j, b) {
      var N;
      const O = ((N = b == null ? void 0 : b[r]) == null ? void 0 : N[v]) || h,
        H = p.useContext(O);
      if (H) return H;
      if (x !== void 0) return x;
      throw new Error(`\`${j}\` must be used within \`${m}\``);
    }
    return [y, M];
  }
  const d = () => {
    const m = a.map((x) => p.createContext(x));
    return function (h) {
      const v = (h == null ? void 0 : h[r]) || m;
      return p.useMemo(() => ({ [`__scope${r}`]: { ...h, [r]: v } }), [h, v]);
    };
  };
  return ((d.scopeName = r), [c, K6(d, ...s)]);
}
function K6(...r) {
  const s = r[0];
  if (r.length === 1) return s;
  const a = () => {
    const c = r.map((d) => ({ useScope: d(), scopeName: d.scopeName }));
    return function (m) {
      const x = c.reduce((h, { useScope: v, scopeName: y }) => {
        const j = v(m)[`__scope${y}`];
        return { ...h, ...j };
      }, {});
      return p.useMemo(() => ({ [`__scope${s.scopeName}`]: x }), [x]);
    };
  };
  return ((a.scopeName = s.scopeName), a);
}
var xl =
    globalThis != null && globalThis.document ? p.useLayoutEffect : () => {},
  Y6 = _a.useId || (() => {}),
  X6 = 0;
function R0(r) {
  const [s, a] = p.useState(Y6());
  return (
    xl(() => {
      a((c) => c ?? String(X6++));
    }, [r]),
    r || (s ? `radix-${s}` : "")
  );
}
function Rn(r) {
  const s = p.useRef(r);
  return (
    p.useEffect(() => {
      s.current = r;
    }),
    p.useMemo(
      () =>
        (...a) => {
          var c;
          return (c = s.current) == null ? void 0 : c.call(s, ...a);
        },
      [],
    )
  );
}
function J6({ prop: r, defaultProp: s, onChange: a = () => {} }) {
  const [c, d] = q6({ defaultProp: s, onChange: a }),
    m = r !== void 0,
    x = m ? r : c,
    h = Rn(a),
    v = p.useCallback(
      (y) => {
        if (m) {
          const j = typeof y == "function" ? y(r) : y;
          j !== r && h(j);
        } else d(y);
      },
      [m, r, d, h],
    );
  return [x, v];
}
function q6({ defaultProp: r, onChange: s }) {
  const a = p.useState(r),
    [c] = a,
    d = p.useRef(c),
    m = Rn(s);
  return (
    p.useEffect(() => {
      d.current !== c && (m(c), (d.current = c));
    }, [c, d, m]),
    a
  );
}
var $0 = p.forwardRef((r, s) => {
  const { children: a, ...c } = r,
    d = p.Children.toArray(a),
    m = d.find(t4);
  if (m) {
    const x = m.props.children,
      h = d.map((v) =>
        v === m
          ? p.Children.count(x) > 1
            ? p.Children.only(null)
            : p.isValidElement(x)
              ? x.props.children
              : null
          : v,
      );
    return i.jsx(B0, {
      ...c,
      ref: s,
      children: p.isValidElement(x) ? p.cloneElement(x, void 0, h) : null,
    });
  }
  return i.jsx(B0, { ...c, ref: s, children: a });
});
$0.displayName = "Slot";
var B0 = p.forwardRef((r, s) => {
  const { children: a, ...c } = r;
  if (p.isValidElement(a)) {
    const d = r4(a),
      m = n4(c, a.props);
    return (
      a.type !== p.Fragment && (m.ref = s ? Ya(s, d) : d),
      p.cloneElement(a, m)
    );
  }
  return p.Children.count(a) > 1 ? p.Children.only(null) : null;
});
B0.displayName = "SlotClone";
var e4 = ({ children: r }) => i.jsx(i.Fragment, { children: r });
function t4(r) {
  return p.isValidElement(r) && r.type === e4;
}
function n4(r, s) {
  const a = { ...s };
  for (const c in s) {
    const d = r[c],
      m = s[c];
    /^on[A-Z]/.test(c)
      ? d && m
        ? (a[c] = (...h) => {
            (m(...h), d(...h));
          })
        : d && (a[c] = d)
      : c === "style"
        ? (a[c] = { ...d, ...m })
        : c === "className" && (a[c] = [d, m].filter(Boolean).join(" "));
  }
  return { ...r, ...a };
}
function r4(r) {
  var c, d;
  let s =
      (c = Object.getOwnPropertyDescriptor(r.props, "ref")) == null
        ? void 0
        : c.get,
    a = s && "isReactWarning" in s && s.isReactWarning;
  return a
    ? r.ref
    : ((s =
        (d = Object.getOwnPropertyDescriptor(r, "ref")) == null
          ? void 0
          : d.get),
      (a = s && "isReactWarning" in s && s.isReactWarning),
      a ? r.props.ref : r.props.ref || r.ref);
}
var l4 = [
    "a",
    "button",
    "div",
    "form",
    "h2",
    "h3",
    "img",
    "input",
    "label",
    "li",
    "nav",
    "ol",
    "p",
    "span",
    "svg",
    "ul",
  ],
  zt = l4.reduce((r, s) => {
    const a = p.forwardRef((c, d) => {
      const { asChild: m, ...x } = c,
        h = m ? $0 : s;
      return (
        typeof window < "u" && (window[Symbol.for("radix-ui")] = !0),
        i.jsx(h, { ...x, ref: d })
      );
    });
    return ((a.displayName = `Primitive.${s}`), { ...r, [s]: a });
  }, {});
function i4(r, s) {
  r && Ia.flushSync(() => r.dispatchEvent(s));
}
function s4(r, s = globalThis == null ? void 0 : globalThis.document) {
  const a = Rn(r);
  p.useEffect(() => {
    const c = (d) => {
      d.key === "Escape" && a(d);
    };
    return (
      s.addEventListener("keydown", c, { capture: !0 }),
      () => s.removeEventListener("keydown", c, { capture: !0 })
    );
  }, [a, s]);
}
var o4 = "DismissableLayer",
  H0 = "dismissableLayer.update",
  a4 = "dismissableLayer.pointerDownOutside",
  u4 = "dismissableLayer.focusOutside",
  Ca,
  Xa = p.createContext({
    layers: new Set(),
    layersWithOutsidePointerEventsDisabled: new Set(),
    branches: new Set(),
  }),
  Ja = p.forwardRef((r, s) => {
    const {
        disableOutsidePointerEvents: a = !1,
        onEscapeKeyDown: c,
        onPointerDownOutside: d,
        onFocusOutside: m,
        onInteractOutside: x,
        onDismiss: h,
        ...v
      } = r,
      y = p.useContext(Xa),
      [M, j] = p.useState(null),
      b =
        (M == null ? void 0 : M.ownerDocument) ??
        (globalThis == null ? void 0 : globalThis.document),
      [, O] = p.useState({}),
      H = bn(s, (Y) => j(Y)),
      N = Array.from(y.layers),
      [k] = [...y.layersWithOutsidePointerEventsDisabled].slice(-1),
      P = N.indexOf(k),
      T = M ? N.indexOf(M) : -1,
      V = y.layersWithOutsidePointerEventsDisabled.size > 0,
      Z = T >= P,
      ee = f4((Y) => {
        const de = Y.target,
          Pe = [...y.branches].some((Ae) => Ae.contains(de));
        !Z ||
          Pe ||
          (d == null || d(Y),
          x == null || x(Y),
          Y.defaultPrevented || h == null || h());
      }, b),
      K = m4((Y) => {
        const de = Y.target;
        [...y.branches].some((Ae) => Ae.contains(de)) ||
          (m == null || m(Y),
          x == null || x(Y),
          Y.defaultPrevented || h == null || h());
      }, b);
    return (
      s4((Y) => {
        T === y.layers.size - 1 &&
          (c == null || c(Y),
          !Y.defaultPrevented && h && (Y.preventDefault(), h()));
      }, b),
      p.useEffect(() => {
        if (M)
          return (
            a &&
              (y.layersWithOutsidePointerEventsDisabled.size === 0 &&
                ((Ca = b.body.style.pointerEvents),
                (b.body.style.pointerEvents = "none")),
              y.layersWithOutsidePointerEventsDisabled.add(M)),
            y.layers.add(M),
            va(),
            () => {
              a &&
                y.layersWithOutsidePointerEventsDisabled.size === 1 &&
                (b.body.style.pointerEvents = Ca);
            }
          );
      }, [M, b, a, y]),
      p.useEffect(
        () => () => {
          M &&
            (y.layers.delete(M),
            y.layersWithOutsidePointerEventsDisabled.delete(M),
            va());
        },
        [M, y],
      ),
      p.useEffect(() => {
        const Y = () => O({});
        return (
          document.addEventListener(H0, Y),
          () => document.removeEventListener(H0, Y)
        );
      }, []),
      i.jsx(zt.div, {
        ...v,
        ref: H,
        style: {
          pointerEvents: V ? (Z ? "auto" : "none") : void 0,
          ...r.style,
        },
        onFocusCapture: dn(r.onFocusCapture, K.onFocusCapture),
        onBlurCapture: dn(r.onBlurCapture, K.onBlurCapture),
        onPointerDownCapture: dn(
          r.onPointerDownCapture,
          ee.onPointerDownCapture,
        ),
      })
    );
  });
Ja.displayName = o4;
var c4 = "DismissableLayerBranch",
  d4 = p.forwardRef((r, s) => {
    const a = p.useContext(Xa),
      c = p.useRef(null),
      d = bn(s, c);
    return (
      p.useEffect(() => {
        const m = c.current;
        if (m)
          return (
            a.branches.add(m),
            () => {
              a.branches.delete(m);
            }
          );
      }, [a.branches]),
      i.jsx(zt.div, { ...r, ref: d })
    );
  });
d4.displayName = c4;
function f4(r, s = globalThis == null ? void 0 : globalThis.document) {
  const a = Rn(r),
    c = p.useRef(!1),
    d = p.useRef(() => {});
  return (
    p.useEffect(() => {
      const m = (h) => {
          if (h.target && !c.current) {
            let v = function () {
              qa(a4, a, y, { discrete: !0 });
            };
            const y = { originalEvent: h };
            h.pointerType === "touch"
              ? (s.removeEventListener("click", d.current),
                (d.current = v),
                s.addEventListener("click", d.current, { once: !0 }))
              : v();
          } else s.removeEventListener("click", d.current);
          c.current = !1;
        },
        x = window.setTimeout(() => {
          s.addEventListener("pointerdown", m);
        }, 0);
      return () => {
        (window.clearTimeout(x),
          s.removeEventListener("pointerdown", m),
          s.removeEventListener("click", d.current));
      };
    }, [s, a]),
    { onPointerDownCapture: () => (c.current = !0) }
  );
}
function m4(r, s = globalThis == null ? void 0 : globalThis.document) {
  const a = Rn(r),
    c = p.useRef(!1);
  return (
    p.useEffect(() => {
      const d = (m) => {
        m.target &&
          !c.current &&
          qa(u4, a, { originalEvent: m }, { discrete: !1 });
      };
      return (
        s.addEventListener("focusin", d),
        () => s.removeEventListener("focusin", d)
      );
    }, [s, a]),
    {
      onFocusCapture: () => (c.current = !0),
      onBlurCapture: () => (c.current = !1),
    }
  );
}
function va() {
  const r = new CustomEvent(H0);
  document.dispatchEvent(r);
}
function qa(r, s, a, { discrete: c }) {
  const d = a.originalEvent.target,
    m = new CustomEvent(r, { bubbles: !1, cancelable: !0, detail: a });
  (s && d.addEventListener(r, s, { once: !0 }),
    c ? i4(d, m) : d.dispatchEvent(m));
}
var M0 = "focusScope.autoFocusOnMount",
  b0 = "focusScope.autoFocusOnUnmount",
  ga = { bubbles: !1, cancelable: !0 },
  h4 = "FocusScope",
  e5 = p.forwardRef((r, s) => {
    const {
        loop: a = !1,
        trapped: c = !1,
        onMountAutoFocus: d,
        onUnmountAutoFocus: m,
        ...x
      } = r,
      [h, v] = p.useState(null),
      y = Rn(d),
      M = Rn(m),
      j = p.useRef(null),
      b = bn(s, (N) => v(N)),
      O = p.useRef({
        paused: !1,
        pause() {
          this.paused = !0;
        },
        resume() {
          this.paused = !1;
        },
      }).current;
    (p.useEffect(() => {
      if (c) {
        let N = function (V) {
            if (O.paused || !h) return;
            const Z = V.target;
            h.contains(Z) ? (j.current = Z) : un(j.current, { select: !0 });
          },
          k = function (V) {
            if (O.paused || !h) return;
            const Z = V.relatedTarget;
            Z !== null && (h.contains(Z) || un(j.current, { select: !0 }));
          },
          P = function (V) {
            if (document.activeElement === document.body)
              for (const ee of V) ee.removedNodes.length > 0 && un(h);
          };
        (document.addEventListener("focusin", N),
          document.addEventListener("focusout", k));
        const T = new MutationObserver(P);
        return (
          h && T.observe(h, { childList: !0, subtree: !0 }),
          () => {
            (document.removeEventListener("focusin", N),
              document.removeEventListener("focusout", k),
              T.disconnect());
          }
        );
      }
    }, [c, h, O.paused]),
      p.useEffect(() => {
        if (h) {
          ya.add(O);
          const N = document.activeElement;
          if (!h.contains(N)) {
            const P = new CustomEvent(M0, ga);
            (h.addEventListener(M0, y),
              h.dispatchEvent(P),
              P.defaultPrevented ||
                (p4(w4(t5(h)), { select: !0 }),
                document.activeElement === N && un(h)));
          }
          return () => {
            (h.removeEventListener(M0, y),
              setTimeout(() => {
                const P = new CustomEvent(b0, ga);
                (h.addEventListener(b0, M),
                  h.dispatchEvent(P),
                  P.defaultPrevented || un(N ?? document.body, { select: !0 }),
                  h.removeEventListener(b0, M),
                  ya.remove(O));
              }, 0));
          };
        }
      }, [h, y, M, O]));
    const H = p.useCallback(
      (N) => {
        if ((!a && !c) || O.paused) return;
        const k = N.key === "Tab" && !N.altKey && !N.ctrlKey && !N.metaKey,
          P = document.activeElement;
        if (k && P) {
          const T = N.currentTarget,
            [V, Z] = x4(T);
          V && Z
            ? !N.shiftKey && P === Z
              ? (N.preventDefault(), a && un(V, { select: !0 }))
              : N.shiftKey &&
                P === V &&
                (N.preventDefault(), a && un(Z, { select: !0 }))
            : P === T && N.preventDefault();
        }
      },
      [a, c, O.paused],
    );
    return i.jsx(zt.div, { tabIndex: -1, ...x, ref: b, onKeyDown: H });
  });
e5.displayName = h4;
function p4(r, { select: s = !1 } = {}) {
  const a = document.activeElement;
  for (const c of r)
    if ((un(c, { select: s }), document.activeElement !== a)) return;
}
function x4(r) {
  const s = t5(r),
    a = wa(s, r),
    c = wa(s.reverse(), r);
  return [a, c];
}
function t5(r) {
  const s = [],
    a = document.createTreeWalker(r, NodeFilter.SHOW_ELEMENT, {
      acceptNode: (c) => {
        const d = c.tagName === "INPUT" && c.type === "hidden";
        return c.disabled || c.hidden || d
          ? NodeFilter.FILTER_SKIP
          : c.tabIndex >= 0
            ? NodeFilter.FILTER_ACCEPT
            : NodeFilter.FILTER_SKIP;
      },
    });
  for (; a.nextNode(); ) s.push(a.currentNode);
  return s;
}
function wa(r, s) {
  for (const a of r) if (!C4(a, { upTo: s })) return a;
}
function C4(r, { upTo: s }) {
  if (getComputedStyle(r).visibility === "hidden") return !0;
  for (; r; ) {
    if (s !== void 0 && r === s) return !1;
    if (getComputedStyle(r).display === "none") return !0;
    r = r.parentElement;
  }
  return !1;
}
function v4(r) {
  return r instanceof HTMLInputElement && "select" in r;
}
function un(r, { select: s = !1 } = {}) {
  if (r && r.focus) {
    const a = document.activeElement;
    (r.focus({ preventScroll: !0 }), r !== a && v4(r) && s && r.select());
  }
}
var ya = g4();
function g4() {
  let r = [];
  return {
    add(s) {
      const a = r[0];
      (s !== a && (a == null || a.pause()), (r = ja(r, s)), r.unshift(s));
    },
    remove(s) {
      var a;
      ((r = ja(r, s)), (a = r[0]) == null || a.resume());
    },
  };
}
function ja(r, s) {
  const a = [...r],
    c = a.indexOf(s);
  return (c !== -1 && a.splice(c, 1), a);
}
function w4(r) {
  return r.filter((s) => s.tagName !== "A");
}
var y4 = "Portal",
  n5 = p.forwardRef((r, s) => {
    var h;
    const { container: a, ...c } = r,
      [d, m] = p.useState(!1);
    xl(() => m(!0), []);
    const x =
      a ||
      (d &&
        ((h = globalThis == null ? void 0 : globalThis.document) == null
          ? void 0
          : h.body));
    return x ? Iu.createPortal(i.jsx(zt.div, { ...c, ref: s }), x) : null;
  });
n5.displayName = y4;
function j4(r, s) {
  return p.useReducer((a, c) => s[a][c] ?? a, r);
}
var jl = (r) => {
  const { present: s, children: a } = r,
    c = N4(s),
    d =
      typeof a == "function" ? a({ present: c.isPresent }) : p.Children.only(a),
    m = bn(c.ref, L4(d));
  return typeof a == "function" || c.isPresent
    ? p.cloneElement(d, { ref: m })
    : null;
};
jl.displayName = "Presence";
function N4(r) {
  const [s, a] = p.useState(),
    c = p.useRef({}),
    d = p.useRef(r),
    m = p.useRef("none"),
    x = r ? "mounted" : "unmounted",
    [h, v] = j4(x, {
      mounted: { UNMOUNT: "unmounted", ANIMATION_OUT: "unmountSuspended" },
      unmountSuspended: { MOUNT: "mounted", ANIMATION_END: "unmounted" },
      unmounted: { MOUNT: "mounted" },
    });
  return (
    p.useEffect(() => {
      const y = al(c.current);
      m.current = h === "mounted" ? y : "none";
    }, [h]),
    xl(() => {
      const y = c.current,
        M = d.current;
      if (M !== r) {
        const b = m.current,
          O = al(y);
        (r
          ? v("MOUNT")
          : O === "none" || (y == null ? void 0 : y.display) === "none"
            ? v("UNMOUNT")
            : v(M && b !== O ? "ANIMATION_OUT" : "UNMOUNT"),
          (d.current = r));
      }
    }, [r, v]),
    xl(() => {
      if (s) {
        let y;
        const M = s.ownerDocument.defaultView ?? window,
          j = (O) => {
            const N = al(c.current).includes(O.animationName);
            if (O.target === s && N && (v("ANIMATION_END"), !d.current)) {
              const k = s.style.animationFillMode;
              ((s.style.animationFillMode = "forwards"),
                (y = M.setTimeout(() => {
                  s.style.animationFillMode === "forwards" &&
                    (s.style.animationFillMode = k);
                })));
            }
          },
          b = (O) => {
            O.target === s && (m.current = al(c.current));
          };
        return (
          s.addEventListener("animationstart", b),
          s.addEventListener("animationcancel", j),
          s.addEventListener("animationend", j),
          () => {
            (M.clearTimeout(y),
              s.removeEventListener("animationstart", b),
              s.removeEventListener("animationcancel", j),
              s.removeEventListener("animationend", j));
          }
        );
      } else v("ANIMATION_END");
    }, [s, v]),
    {
      isPresent: ["mounted", "unmountSuspended"].includes(h),
      ref: p.useCallback((y) => {
        (y && (c.current = getComputedStyle(y)), a(y));
      }, []),
    }
  );
}
function al(r) {
  return (r == null ? void 0 : r.animationName) || "none";
}
function L4(r) {
  var c, d;
  let s =
      (c = Object.getOwnPropertyDescriptor(r.props, "ref")) == null
        ? void 0
        : c.get,
    a = s && "isReactWarning" in s && s.isReactWarning;
  return a
    ? r.ref
    : ((s =
        (d = Object.getOwnPropertyDescriptor(r, "ref")) == null
          ? void 0
          : d.get),
      (a = s && "isReactWarning" in s && s.isReactWarning),
      a ? r.props.ref : r.props.ref || r.ref);
}
var P0 = 0;
function E4() {
  p.useEffect(() => {
    const r = document.querySelectorAll("[data-radix-focus-guard]");
    return (
      document.body.insertAdjacentElement("afterbegin", r[0] ?? Na()),
      document.body.insertAdjacentElement("beforeend", r[1] ?? Na()),
      P0++,
      () => {
        (P0 === 1 &&
          document
            .querySelectorAll("[data-radix-focus-guard]")
            .forEach((s) => s.remove()),
          P0--);
      }
    );
  }, []);
}
function Na() {
  const r = document.createElement("span");
  return (
    r.setAttribute("data-radix-focus-guard", ""),
    (r.tabIndex = 0),
    (r.style.outline = "none"),
    (r.style.opacity = "0"),
    (r.style.position = "fixed"),
    (r.style.pointerEvents = "none"),
    r
  );
}
var Ot = function () {
  return (
    (Ot =
      Object.assign ||
      function (s) {
        for (var a, c = 1, d = arguments.length; c < d; c++) {
          a = arguments[c];
          for (var m in a)
            Object.prototype.hasOwnProperty.call(a, m) && (s[m] = a[m]);
        }
        return s;
      }),
    Ot.apply(this, arguments)
  );
};
function r5(r, s) {
  var a = {};
  for (var c in r)
    Object.prototype.hasOwnProperty.call(r, c) &&
      s.indexOf(c) < 0 &&
      (a[c] = r[c]);
  if (r != null && typeof Object.getOwnPropertySymbols == "function")
    for (var d = 0, c = Object.getOwnPropertySymbols(r); d < c.length; d++)
      s.indexOf(c[d]) < 0 &&
        Object.prototype.propertyIsEnumerable.call(r, c[d]) &&
        (a[c[d]] = r[c[d]]);
  return a;
}
function S4(r, s, a) {
  if (a || arguments.length === 2)
    for (var c = 0, d = s.length, m; c < d; c++)
      (m || !(c in s)) &&
        (m || (m = Array.prototype.slice.call(s, 0, c)), (m[c] = s[c]));
  return r.concat(m || Array.prototype.slice.call(s));
}
var hl = "right-scroll-bar-position",
  pl = "width-before-scroll-bar",
  k4 = "with-scroll-bars-hidden",
  R4 = "--removed-body-scroll-bar-size";
function O0(r, s) {
  return (typeof r == "function" ? r(s) : r && (r.current = s), r);
}
function M4(r, s) {
  var a = p.useState(function () {
    return {
      value: r,
      callback: s,
      facade: {
        get current() {
          return a.value;
        },
        set current(c) {
          var d = a.value;
          d !== c && ((a.value = c), a.callback(c, d));
        },
      },
    };
  })[0];
  return ((a.callback = s), a.facade);
}
var b4 = typeof window < "u" ? p.useLayoutEffect : p.useEffect,
  La = new WeakMap();
function P4(r, s) {
  var a = M4(null, function (c) {
    return r.forEach(function (d) {
      return O0(d, c);
    });
  });
  return (
    b4(
      function () {
        var c = La.get(a);
        if (c) {
          var d = new Set(c),
            m = new Set(r),
            x = a.current;
          (d.forEach(function (h) {
            m.has(h) || O0(h, null);
          }),
            m.forEach(function (h) {
              d.has(h) || O0(h, x);
            }));
        }
        La.set(a, r);
      },
      [r],
    ),
    a
  );
}
function O4(r) {
  return r;
}
function _4(r, s) {
  s === void 0 && (s = O4);
  var a = [],
    c = !1,
    d = {
      read: function () {
        if (c)
          throw new Error(
            "Sidecar: could not `read` from an `assigned` medium. `read` could be used only with `useMedium`.",
          );
        return a.length ? a[a.length - 1] : r;
      },
      useMedium: function (m) {
        var x = s(m, c);
        return (
          a.push(x),
          function () {
            a = a.filter(function (h) {
              return h !== x;
            });
          }
        );
      },
      assignSyncMedium: function (m) {
        for (c = !0; a.length; ) {
          var x = a;
          ((a = []), x.forEach(m));
        }
        a = {
          push: function (h) {
            return m(h);
          },
          filter: function () {
            return a;
          },
        };
      },
      assignMedium: function (m) {
        c = !0;
        var x = [];
        if (a.length) {
          var h = a;
          ((a = []), h.forEach(m), (x = a));
        }
        var v = function () {
            var M = x;
            ((x = []), M.forEach(m));
          },
          y = function () {
            return Promise.resolve().then(v);
          };
        (y(),
          (a = {
            push: function (M) {
              (x.push(M), y());
            },
            filter: function (M) {
              return ((x = x.filter(M)), a);
            },
          }));
      },
    };
  return d;
}
function F4(r) {
  r === void 0 && (r = {});
  var s = _4(null);
  return ((s.options = Ot({ async: !0, ssr: !1 }, r)), s);
}
var l5 = function (r) {
  var s = r.sideCar,
    a = r5(r, ["sideCar"]);
  if (!s)
    throw new Error(
      "Sidecar: please provide `sideCar` property to import the right car",
    );
  var c = s.read();
  if (!c) throw new Error("Sidecar medium not found");
  return p.createElement(c, Ot({}, a));
};
l5.isSideCarExport = !0;
function I4(r, s) {
  return (r.useMedium(s), l5);
}
var i5 = F4(),
  _0 = function () {},
  Nl = p.forwardRef(function (r, s) {
    var a = p.useRef(null),
      c = p.useState({
        onScrollCapture: _0,
        onWheelCapture: _0,
        onTouchMoveCapture: _0,
      }),
      d = c[0],
      m = c[1],
      x = r.forwardProps,
      h = r.children,
      v = r.className,
      y = r.removeScrollBar,
      M = r.enabled,
      j = r.shards,
      b = r.sideCar,
      O = r.noIsolation,
      H = r.inert,
      N = r.allowPinchZoom,
      k = r.as,
      P = k === void 0 ? "div" : k,
      T = r.gapMode,
      V = r5(r, [
        "forwardProps",
        "children",
        "className",
        "removeScrollBar",
        "enabled",
        "shards",
        "sideCar",
        "noIsolation",
        "inert",
        "allowPinchZoom",
        "as",
        "gapMode",
      ]),
      Z = b,
      ee = P4([a, s]),
      K = Ot(Ot({}, V), d);
    return p.createElement(
      p.Fragment,
      null,
      M &&
        p.createElement(Z, {
          sideCar: i5,
          removeScrollBar: y,
          shards: j,
          noIsolation: O,
          inert: H,
          setCallbacks: m,
          allowPinchZoom: !!N,
          lockRef: a,
          gapMode: T,
        }),
      x
        ? p.cloneElement(p.Children.only(h), Ot(Ot({}, K), { ref: ee }))
        : p.createElement(P, Ot({}, K, { className: v, ref: ee }), h),
    );
  });
Nl.defaultProps = { enabled: !0, removeScrollBar: !0, inert: !1 };
Nl.classNames = { fullWidth: pl, zeroRight: hl };
var D4 = function () {
  if (typeof __webpack_nonce__ < "u") return __webpack_nonce__;
};
function T4() {
  if (!document) return null;
  var r = document.createElement("style");
  r.type = "text/css";
  var s = D4();
  return (s && r.setAttribute("nonce", s), r);
}
function A4(r, s) {
  r.styleSheet
    ? (r.styleSheet.cssText = s)
    : r.appendChild(document.createTextNode(s));
}
function B4(r) {
  var s = document.head || document.getElementsByTagName("head")[0];
  s.appendChild(r);
}
var H4 = function () {
    var r = 0,
      s = null;
    return {
      add: function (a) {
        (r == 0 && (s = T4()) && (A4(s, a), B4(s)), r++);
      },
      remove: function () {
        (r--,
          !r && s && (s.parentNode && s.parentNode.removeChild(s), (s = null)));
      },
    };
  },
  V4 = function () {
    var r = H4();
    return function (s, a) {
      p.useEffect(
        function () {
          return (
            r.add(s),
            function () {
              r.remove();
            }
          );
        },
        [s && a],
      );
    };
  },
  s5 = function () {
    var r = V4(),
      s = function (a) {
        var c = a.styles,
          d = a.dynamic;
        return (r(c, d), null);
      };
    return s;
  },
  z4 = { left: 0, top: 0, right: 0, gap: 0 },
  F0 = function (r) {
    return parseInt(r || "", 10) || 0;
  },
  U4 = function (r) {
    var s = window.getComputedStyle(document.body),
      a = s[r === "padding" ? "paddingLeft" : "marginLeft"],
      c = s[r === "padding" ? "paddingTop" : "marginTop"],
      d = s[r === "padding" ? "paddingRight" : "marginRight"];
    return [F0(a), F0(c), F0(d)];
  },
  Z4 = function (r) {
    if ((r === void 0 && (r = "margin"), typeof window > "u")) return z4;
    var s = U4(r),
      a = document.documentElement.clientWidth,
      c = window.innerWidth;
    return {
      left: s[0],
      top: s[1],
      right: s[2],
      gap: Math.max(0, c - a + s[2] - s[0]),
    };
  },
  W4 = s5(),
  ir = "data-scroll-locked",
  $4 = function (r, s, a, c) {
    var d = r.left,
      m = r.top,
      x = r.right,
      h = r.gap;
    return (
      a === void 0 && (a = "margin"),
      `
  .`
        .concat(
          k4,
          ` {
   overflow: hidden `,
        )
        .concat(
          c,
          `;
   padding-right: `,
        )
        .concat(h, "px ")
        .concat(
          c,
          `;
  }
  body[`,
        )
        .concat(
          ir,
          `] {
    overflow: hidden `,
        )
        .concat(
          c,
          `;
    overscroll-behavior: contain;
    `,
        )
        .concat(
          [
            s && "position: relative ".concat(c, ";"),
            a === "margin" &&
              `
    padding-left: `
                .concat(
                  d,
                  `px;
    padding-top: `,
                )
                .concat(
                  m,
                  `px;
    padding-right: `,
                )
                .concat(
                  x,
                  `px;
    margin-left:0;
    margin-top:0;
    margin-right: `,
                )
                .concat(h, "px ")
                .concat(
                  c,
                  `;
    `,
                ),
            a === "padding" &&
              "padding-right: ".concat(h, "px ").concat(c, ";"),
          ]
            .filter(Boolean)
            .join(""),
          `
  }
  
  .`,
        )
        .concat(
          hl,
          ` {
    right: `,
        )
        .concat(h, "px ")
        .concat(
          c,
          `;
  }
  
  .`,
        )
        .concat(
          pl,
          ` {
    margin-right: `,
        )
        .concat(h, "px ")
        .concat(
          c,
          `;
  }
  
  .`,
        )
        .concat(hl, " .")
        .concat(
          hl,
          ` {
    right: 0 `,
        )
        .concat(
          c,
          `;
  }
  
  .`,
        )
        .concat(pl, " .")
        .concat(
          pl,
          ` {
    margin-right: 0 `,
        )
        .concat(
          c,
          `;
  }
  
  body[`,
        )
        .concat(
          ir,
          `] {
    `,
        )
        .concat(R4, ": ")
        .concat(
          h,
          `px;
  }
`,
        )
    );
  },
  Ea = function () {
    var r = parseInt(document.body.getAttribute(ir) || "0", 10);
    return isFinite(r) ? r : 0;
  },
  G4 = function () {
    p.useEffect(function () {
      return (
        document.body.setAttribute(ir, (Ea() + 1).toString()),
        function () {
          var r = Ea() - 1;
          r <= 0
            ? document.body.removeAttribute(ir)
            : document.body.setAttribute(ir, r.toString());
        }
      );
    }, []);
  },
  Q4 = function (r) {
    var s = r.noRelative,
      a = r.noImportant,
      c = r.gapMode,
      d = c === void 0 ? "margin" : c;
    G4();
    var m = p.useMemo(
      function () {
        return Z4(d);
      },
      [d],
    );
    return p.createElement(W4, { styles: $4(m, !s, d, a ? "" : "!important") });
  },
  V0 = !1;
if (typeof window < "u")
  try {
    var ul = Object.defineProperty({}, "passive", {
      get: function () {
        return ((V0 = !0), !0);
      },
    });
    (window.addEventListener("test", ul, ul),
      window.removeEventListener("test", ul, ul));
  } catch {
    V0 = !1;
  }
var nr = V0 ? { passive: !1 } : !1,
  K4 = function (r) {
    return r.tagName === "TEXTAREA";
  },
  o5 = function (r, s) {
    if (!(r instanceof Element)) return !1;
    var a = window.getComputedStyle(r);
    return (
      a[s] !== "hidden" &&
      !(a.overflowY === a.overflowX && !K4(r) && a[s] === "visible")
    );
  },
  Y4 = function (r) {
    return o5(r, "overflowY");
  },
  X4 = function (r) {
    return o5(r, "overflowX");
  },
  Sa = function (r, s) {
    var a = s.ownerDocument,
      c = s;
    do {
      typeof ShadowRoot < "u" && c instanceof ShadowRoot && (c = c.host);
      var d = a5(r, c);
      if (d) {
        var m = u5(r, c),
          x = m[1],
          h = m[2];
        if (x > h) return !0;
      }
      c = c.parentNode;
    } while (c && c !== a.body);
    return !1;
  },
  J4 = function (r) {
    var s = r.scrollTop,
      a = r.scrollHeight,
      c = r.clientHeight;
    return [s, a, c];
  },
  q4 = function (r) {
    var s = r.scrollLeft,
      a = r.scrollWidth,
      c = r.clientWidth;
    return [s, a, c];
  },
  a5 = function (r, s) {
    return r === "v" ? Y4(s) : X4(s);
  },
  u5 = function (r, s) {
    return r === "v" ? J4(s) : q4(s);
  },
  e9 = function (r, s) {
    return r === "h" && s === "rtl" ? -1 : 1;
  },
  t9 = function (r, s, a, c, d) {
    var m = e9(r, window.getComputedStyle(s).direction),
      x = m * c,
      h = a.target,
      v = s.contains(h),
      y = !1,
      M = x > 0,
      j = 0,
      b = 0;
    do {
      var O = u5(r, h),
        H = O[0],
        N = O[1],
        k = O[2],
        P = N - k - m * H;
      ((H || P) && a5(r, h) && ((j += P), (b += H)),
        h instanceof ShadowRoot ? (h = h.host) : (h = h.parentNode));
    } while ((!v && h !== document.body) || (v && (s.contains(h) || s === h)));
    return (((M && Math.abs(j) < 1) || (!M && Math.abs(b) < 1)) && (y = !0), y);
  },
  cl = function (r) {
    return "changedTouches" in r
      ? [r.changedTouches[0].clientX, r.changedTouches[0].clientY]
      : [0, 0];
  },
  ka = function (r) {
    return [r.deltaX, r.deltaY];
  },
  Ra = function (r) {
    return r && "current" in r ? r.current : r;
  },
  n9 = function (r, s) {
    return r[0] === s[0] && r[1] === s[1];
  },
  r9 = function (r) {
    return `
  .block-interactivity-`
      .concat(
        r,
        ` {pointer-events: none;}
  .allow-interactivity-`,
      )
      .concat(
        r,
        ` {pointer-events: all;}
`,
      );
  },
  l9 = 0,
  rr = [];
function i9(r) {
  var s = p.useRef([]),
    a = p.useRef([0, 0]),
    c = p.useRef(),
    d = p.useState(l9++)[0],
    m = p.useState(s5)[0],
    x = p.useRef(r);
  (p.useEffect(
    function () {
      x.current = r;
    },
    [r],
  ),
    p.useEffect(
      function () {
        if (r.inert) {
          document.body.classList.add("block-interactivity-".concat(d));
          var N = S4([r.lockRef.current], (r.shards || []).map(Ra), !0).filter(
            Boolean,
          );
          return (
            N.forEach(function (k) {
              return k.classList.add("allow-interactivity-".concat(d));
            }),
            function () {
              (document.body.classList.remove("block-interactivity-".concat(d)),
                N.forEach(function (k) {
                  return k.classList.remove("allow-interactivity-".concat(d));
                }));
            }
          );
        }
      },
      [r.inert, r.lockRef.current, r.shards],
    ));
  var h = p.useCallback(function (N, k) {
      if (
        ("touches" in N && N.touches.length === 2) ||
        (N.type === "wheel" && N.ctrlKey)
      )
        return !x.current.allowPinchZoom;
      var P = cl(N),
        T = a.current,
        V = "deltaX" in N ? N.deltaX : T[0] - P[0],
        Z = "deltaY" in N ? N.deltaY : T[1] - P[1],
        ee,
        K = N.target,
        Y = Math.abs(V) > Math.abs(Z) ? "h" : "v";
      if ("touches" in N && Y === "h" && K.type === "range") return !1;
      var de = Sa(Y, K);
      if (!de) return !0;
      if (
        (de ? (ee = Y) : ((ee = Y === "v" ? "h" : "v"), (de = Sa(Y, K))), !de)
      )
        return !1;
      if (
        (!c.current && "changedTouches" in N && (V || Z) && (c.current = ee),
        !ee)
      )
        return !0;
      var Pe = c.current || ee;
      return t9(Pe, k, N, Pe === "h" ? V : Z);
    }, []),
    v = p.useCallback(function (N) {
      var k = N;
      if (!(!rr.length || rr[rr.length - 1] !== m)) {
        var P = "deltaY" in k ? ka(k) : cl(k),
          T = s.current.filter(function (ee) {
            return (
              ee.name === k.type &&
              (ee.target === k.target || k.target === ee.shadowParent) &&
              n9(ee.delta, P)
            );
          })[0];
        if (T && T.should) {
          k.cancelable && k.preventDefault();
          return;
        }
        if (!T) {
          var V = (x.current.shards || [])
              .map(Ra)
              .filter(Boolean)
              .filter(function (ee) {
                return ee.contains(k.target);
              }),
            Z = V.length > 0 ? h(k, V[0]) : !x.current.noIsolation;
          Z && k.cancelable && k.preventDefault();
        }
      }
    }, []),
    y = p.useCallback(function (N, k, P, T) {
      var V = { name: N, delta: k, target: P, should: T, shadowParent: s9(P) };
      (s.current.push(V),
        setTimeout(function () {
          s.current = s.current.filter(function (Z) {
            return Z !== V;
          });
        }, 1));
    }, []),
    M = p.useCallback(function (N) {
      ((a.current = cl(N)), (c.current = void 0));
    }, []),
    j = p.useCallback(function (N) {
      y(N.type, ka(N), N.target, h(N, r.lockRef.current));
    }, []),
    b = p.useCallback(function (N) {
      y(N.type, cl(N), N.target, h(N, r.lockRef.current));
    }, []);
  p.useEffect(function () {
    return (
      rr.push(m),
      r.setCallbacks({
        onScrollCapture: j,
        onWheelCapture: j,
        onTouchMoveCapture: b,
      }),
      document.addEventListener("wheel", v, nr),
      document.addEventListener("touchmove", v, nr),
      document.addEventListener("touchstart", M, nr),
      function () {
        ((rr = rr.filter(function (N) {
          return N !== m;
        })),
          document.removeEventListener("wheel", v, nr),
          document.removeEventListener("touchmove", v, nr),
          document.removeEventListener("touchstart", M, nr));
      }
    );
  }, []);
  var O = r.removeScrollBar,
    H = r.inert;
  return p.createElement(
    p.Fragment,
    null,
    H ? p.createElement(m, { styles: r9(d) }) : null,
    O ? p.createElement(Q4, { gapMode: r.gapMode }) : null,
  );
}
function s9(r) {
  for (var s = null; r !== null; )
    (r instanceof ShadowRoot && ((s = r.host), (r = r.host)),
      (r = r.parentNode));
  return s;
}
const o9 = I4(i5, i9);
var c5 = p.forwardRef(function (r, s) {
  return p.createElement(Nl, Ot({}, r, { ref: s, sideCar: o9 }));
});
c5.classNames = Nl.classNames;
var a9 = function (r) {
    if (typeof document > "u") return null;
    var s = Array.isArray(r) ? r[0] : r;
    return s.ownerDocument.body;
  },
  lr = new WeakMap(),
  dl = new WeakMap(),
  fl = {},
  I0 = 0,
  d5 = function (r) {
    return r && (r.host || d5(r.parentNode));
  },
  u9 = function (r, s) {
    return s
      .map(function (a) {
        if (r.contains(a)) return a;
        var c = d5(a);
        return c && r.contains(c)
          ? c
          : (console.error(
              "aria-hidden",
              a,
              "in not contained inside",
              r,
              ". Doing nothing",
            ),
            null);
      })
      .filter(function (a) {
        return !!a;
      });
  },
  c9 = function (r, s, a, c) {
    var d = u9(s, Array.isArray(r) ? r : [r]);
    fl[a] || (fl[a] = new WeakMap());
    var m = fl[a],
      x = [],
      h = new Set(),
      v = new Set(d),
      y = function (j) {
        !j || h.has(j) || (h.add(j), y(j.parentNode));
      };
    d.forEach(y);
    var M = function (j) {
      !j ||
        v.has(j) ||
        Array.prototype.forEach.call(j.children, function (b) {
          if (h.has(b)) M(b);
          else
            try {
              var O = b.getAttribute(c),
                H = O !== null && O !== "false",
                N = (lr.get(b) || 0) + 1,
                k = (m.get(b) || 0) + 1;
              (lr.set(b, N),
                m.set(b, k),
                x.push(b),
                N === 1 && H && dl.set(b, !0),
                k === 1 && b.setAttribute(a, "true"),
                H || b.setAttribute(c, "true"));
            } catch (P) {
              console.error("aria-hidden: cannot operate on ", b, P);
            }
        });
    };
    return (
      M(s),
      h.clear(),
      I0++,
      function () {
        (x.forEach(function (j) {
          var b = lr.get(j) - 1,
            O = m.get(j) - 1;
          (lr.set(j, b),
            m.set(j, O),
            b || (dl.has(j) || j.removeAttribute(c), dl.delete(j)),
            O || j.removeAttribute(a));
        }),
          I0--,
          I0 ||
            ((lr = new WeakMap()),
            (lr = new WeakMap()),
            (dl = new WeakMap()),
            (fl = {})));
      }
    );
  },
  d9 = function (r, s, a) {
    a === void 0 && (a = "data-aria-hidden");
    var c = Array.from(Array.isArray(r) ? r : [r]),
      d = a9(r);
    return d
      ? (c.push.apply(c, Array.from(d.querySelectorAll("[aria-live]"))),
        c9(c, d, a, "aria-hidden"))
      : function () {
          return null;
        };
  },
  G0 = "Dialog",
  [f5, N8] = Q6(G0),
  [f9, yt] = f5(G0),
  m5 = (r) => {
    const {
        __scopeDialog: s,
        children: a,
        open: c,
        defaultOpen: d,
        onOpenChange: m,
        modal: x = !0,
      } = r,
      h = p.useRef(null),
      v = p.useRef(null),
      [y = !1, M] = J6({ prop: c, defaultProp: d, onChange: m });
    return i.jsx(f9, {
      scope: s,
      triggerRef: h,
      contentRef: v,
      contentId: R0(),
      titleId: R0(),
      descriptionId: R0(),
      open: y,
      onOpenChange: M,
      onOpenToggle: p.useCallback(() => M((j) => !j), [M]),
      modal: x,
      children: a,
    });
  };
m5.displayName = G0;
var h5 = "DialogTrigger",
  p5 = p.forwardRef((r, s) => {
    const { __scopeDialog: a, ...c } = r,
      d = yt(h5, a),
      m = bn(s, d.triggerRef);
    return i.jsx(zt.button, {
      type: "button",
      "aria-haspopup": "dialog",
      "aria-expanded": d.open,
      "aria-controls": d.contentId,
      "data-state": Y0(d.open),
      ...c,
      ref: m,
      onClick: dn(r.onClick, d.onOpenToggle),
    });
  });
p5.displayName = h5;
var Q0 = "DialogPortal",
  [m9, x5] = f5(Q0, { forceMount: void 0 }),
  C5 = (r) => {
    const { __scopeDialog: s, forceMount: a, children: c, container: d } = r,
      m = yt(Q0, s);
    return i.jsx(m9, {
      scope: s,
      forceMount: a,
      children: p.Children.map(c, (x) =>
        i.jsx(jl, {
          present: a || m.open,
          children: i.jsx(n5, { asChild: !0, container: d, children: x }),
        }),
      ),
    });
  };
C5.displayName = Q0;
var Cl = "DialogOverlay",
  v5 = p.forwardRef((r, s) => {
    const a = x5(Cl, r.__scopeDialog),
      { forceMount: c = a.forceMount, ...d } = r,
      m = yt(Cl, r.__scopeDialog);
    return m.modal
      ? i.jsx(jl, {
          present: c || m.open,
          children: i.jsx(h9, { ...d, ref: s }),
        })
      : null;
  });
v5.displayName = Cl;
var h9 = p.forwardRef((r, s) => {
    const { __scopeDialog: a, ...c } = r,
      d = yt(Cl, a);
    return i.jsx(c5, {
      as: $0,
      allowPinchZoom: !0,
      shards: [d.contentRef],
      children: i.jsx(zt.div, {
        "data-state": Y0(d.open),
        ...c,
        ref: s,
        style: { pointerEvents: "auto", ...c.style },
      }),
    });
  }),
  Mn = "DialogContent",
  g5 = p.forwardRef((r, s) => {
    const a = x5(Mn, r.__scopeDialog),
      { forceMount: c = a.forceMount, ...d } = r,
      m = yt(Mn, r.__scopeDialog);
    return i.jsx(jl, {
      present: c || m.open,
      children: m.modal
        ? i.jsx(p9, { ...d, ref: s })
        : i.jsx(x9, { ...d, ref: s }),
    });
  });
g5.displayName = Mn;
var p9 = p.forwardRef((r, s) => {
    const a = yt(Mn, r.__scopeDialog),
      c = p.useRef(null),
      d = bn(s, a.contentRef, c);
    return (
      p.useEffect(() => {
        const m = c.current;
        if (m) return d9(m);
      }, []),
      i.jsx(w5, {
        ...r,
        ref: d,
        trapFocus: a.open,
        disableOutsidePointerEvents: !0,
        onCloseAutoFocus: dn(r.onCloseAutoFocus, (m) => {
          var x;
          (m.preventDefault(), (x = a.triggerRef.current) == null || x.focus());
        }),
        onPointerDownOutside: dn(r.onPointerDownOutside, (m) => {
          const x = m.detail.originalEvent,
            h = x.button === 0 && x.ctrlKey === !0;
          (x.button === 2 || h) && m.preventDefault();
        }),
        onFocusOutside: dn(r.onFocusOutside, (m) => m.preventDefault()),
      })
    );
  }),
  x9 = p.forwardRef((r, s) => {
    const a = yt(Mn, r.__scopeDialog),
      c = p.useRef(!1),
      d = p.useRef(!1);
    return i.jsx(w5, {
      ...r,
      ref: s,
      trapFocus: !1,
      disableOutsidePointerEvents: !1,
      onCloseAutoFocus: (m) => {
        var x, h;
        ((x = r.onCloseAutoFocus) == null || x.call(r, m),
          m.defaultPrevented ||
            (c.current || (h = a.triggerRef.current) == null || h.focus(),
            m.preventDefault()),
          (c.current = !1),
          (d.current = !1));
      },
      onInteractOutside: (m) => {
        var v, y;
        ((v = r.onInteractOutside) == null || v.call(r, m),
          m.defaultPrevented ||
            ((c.current = !0),
            m.detail.originalEvent.type === "pointerdown" && (d.current = !0)));
        const x = m.target;
        (((y = a.triggerRef.current) == null ? void 0 : y.contains(x)) &&
          m.preventDefault(),
          m.detail.originalEvent.type === "focusin" &&
            d.current &&
            m.preventDefault());
      },
    });
  }),
  w5 = p.forwardRef((r, s) => {
    const {
        __scopeDialog: a,
        trapFocus: c,
        onOpenAutoFocus: d,
        onCloseAutoFocus: m,
        ...x
      } = r,
      h = yt(Mn, a),
      v = p.useRef(null),
      y = bn(s, v);
    return (
      E4(),
      i.jsxs(i.Fragment, {
        children: [
          i.jsx(e5, {
            asChild: !0,
            loop: !0,
            trapped: c,
            onMountAutoFocus: d,
            onUnmountAutoFocus: m,
            children: i.jsx(Ja, {
              role: "dialog",
              id: h.contentId,
              "aria-describedby": h.descriptionId,
              "aria-labelledby": h.titleId,
              "data-state": Y0(h.open),
              ...x,
              ref: y,
              onDismiss: () => h.onOpenChange(!1),
            }),
          }),
          i.jsxs(i.Fragment, {
            children: [
              i.jsx(C9, { titleId: h.titleId }),
              i.jsx(g9, { contentRef: v, descriptionId: h.descriptionId }),
            ],
          }),
        ],
      })
    );
  }),
  K0 = "DialogTitle",
  y5 = p.forwardRef((r, s) => {
    const { __scopeDialog: a, ...c } = r,
      d = yt(K0, a);
    return i.jsx(zt.h2, { id: d.titleId, ...c, ref: s });
  });
y5.displayName = K0;
var j5 = "DialogDescription",
  N5 = p.forwardRef((r, s) => {
    const { __scopeDialog: a, ...c } = r,
      d = yt(j5, a);
    return i.jsx(zt.p, { id: d.descriptionId, ...c, ref: s });
  });
N5.displayName = j5;
var L5 = "DialogClose",
  E5 = p.forwardRef((r, s) => {
    const { __scopeDialog: a, ...c } = r,
      d = yt(L5, a);
    return i.jsx(zt.button, {
      type: "button",
      ...c,
      ref: s,
      onClick: dn(r.onClick, () => d.onOpenChange(!1)),
    });
  });
E5.displayName = L5;
function Y0(r) {
  return r ? "open" : "closed";
}
var S5 = "DialogTitleWarning",
  [L8, k5] = G6(S5, { contentName: Mn, titleName: K0, docsSlug: "dialog" }),
  C9 = ({ titleId: r }) => {
    const s = k5(S5),
      a = `\`${s.contentName}\` requires a \`${s.titleName}\` for the component to be accessible for screen reader users.

If you want to hide the \`${s.titleName}\`, you can wrap it with our VisuallyHidden component.

For more information, see https://radix-ui.com/primitives/docs/components/${s.docsSlug}`;
    return (
      p.useEffect(() => {
        r && (document.getElementById(r) || console.error(a));
      }, [a, r]),
      null
    );
  },
  v9 = "DialogDescriptionWarning",
  g9 = ({ contentRef: r, descriptionId: s }) => {
    const c = `Warning: Missing \`Description\` or \`aria-describedby={undefined}\` for {${k5(v9).contentName}}.`;
    return (
      p.useEffect(() => {
        var m;
        const d =
          (m = r.current) == null ? void 0 : m.getAttribute("aria-describedby");
        s && d && (document.getElementById(s) || console.warn(c));
      }, [c, r, s]),
      null
    );
  },
  jt = m5,
  Nt = p5,
  Lt = C5,
  Et = v5,
  St = g5,
  Ll = y5,
  w9 = N5,
  qe = E5;
function y9({ currentAvatar: r }) {
  const { update: s } = Ze(),
    [a, c] = p.useState(!1),
    d = p.useRef(null),
    m = () => {
      var h;
      const x = (h = d.current) == null ? void 0 : h.value;
      x &&
        se("UpdateAvatar", { url: x }, !0).then((v) => {
          v && (c(!1), s({ avatar: x }));
        });
    };
  return i.jsxs(jt, {
    open: a,
    onOpenChange: c,
    children: [
      i.jsx(Nt, {
        asChild: !0,
        children: i.jsx("button", {
          className:
            "absolute inset-0 flex items-center justify-center bg-black rounded-full opacity-0 group-hover:opacity-80 transition-opacity z-10",
          children: i.jsxs("svg", {
            width: "1.5rem",
            height: "1.5rem",
            viewBox: "0 0 24 24",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
              i.jsx("path", {
                d: "M11 4H4C3.46957 4 2.96086 4.21071 2.58579 4.58579C2.21071 4.96086 2 5.46957 2 6V20C2 20.5304 2.21071 21.0391 2.58579 21.4142C2.96086 21.7893 3.46957 22 4 22H18C18.5304 22 19.0391 21.7893 19.4142 21.4142C19.7893 21.0391 20 20.5304 20 20V13",
                stroke: "white",
                strokeWidth: "2",
                strokeLinecap: "round",
                strokeLinejoin: "round",
              }),
              i.jsx("path", {
                d: "M18.5 2.50023C18.8978 2.10243 19.4374 1.87891 20 1.87891C20.5626 1.87891 21.1022 2.10243 21.5 2.50023C21.8978 2.89804 22.1213 3.43762 22.1213 4.00023C22.1213 4.56284 21.8978 5.10243 21.5 5.50023L12 15.0002L8 16.0002L9 12.0002L18.5 2.50023Z",
                stroke: "white",
                strokeWidth: "2",
                strokeLinecap: "round",
                strokeLinejoin: "round",
              }),
            ],
          }),
        }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22rem] p-4 rounded-[.5625rem] flex flex-col gap-4 border-[.0563rem] border-white/10 bg-[#151716]",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2",
                children: [
                  i.jsxs("svg", {
                    width: "1rem",
                    height: "1rem",
                    viewBox: "0 0 24 24",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: [
                      i.jsx("path", {
                        d: "M11 4H4C3.46957 4 2.96086 4.21071 2.58579 4.58579C2.21071 4.96086 2 5.46957 2 6V20C2 20.5304 2.21071 21.0391 2.58579 21.4142C2.96086 21.7893 3.46957 22 4 22H18C18.5304 22 19.0391 21.7893 19.4142 21.4142C19.7893 21.0391 20 20.5304 20 20V13",
                        stroke: "white",
                        strokeWidth: "2",
                        strokeLinecap: "round",
                        strokeLinejoin: "round",
                        opacity: "0.25",
                      }),
                      i.jsx("path", {
                        d: "M18.5 2.50023C18.8978 2.10243 19.4374 1.87891 20 1.87891C20.5626 1.87891 21.1022 2.10243 21.5 2.50023C21.8978 2.89804 22.1213 3.43762 22.1213 4.00023C22.1213 4.56284 21.8978 5.10243 21.5 5.50023L12 15.0002L8 16.0002L9 12.0002L18.5 2.50023Z",
                        stroke: "white",
                        strokeWidth: "2",
                        strokeLinecap: "round",
                        strokeLinejoin: "round",
                        opacity: "0.25",
                      }),
                    ],
                  }),
                  i.jsx(Ll, {
                    className: "text-white/65 text-sm font-bold",
                    children: "EDITAR AVATAR",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "URL DA IMAGEM",
                  }),
                  i.jsx("input", {
                    type: "text",
                    ref: d,
                    placeholder: "DIGITE A URL DA IMAGEM",
                    defaultValue: r,
                    className:
                      "w-full h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 text-white/35 text-xs font-medium rounded-[.3125rem] placeholder:text-white/35 outline-none",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx("button", {
                    onClick: m,
                    className:
                      "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                    children: "SALVAR",
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function j9({ children: r }) {
  const s = Za(),
    { pathname: a } = Z0(),
    {
      update: c,
      avatar: d,
      orgName: m,
      membersOnline: x,
      orgBalance: h,
      members: v,
      maxMembers: y,
    } = Ze();
  return (
    kn("UpdateWarnings", (M) => c({ warnings: M })),
    i.jsxs("div", {
      className:
        "w-[85.375rem] h-[52.5rem] bg-[#151716] p-3 rounded-[.875rem] flex flex-col gap-3",
      children: [
        i.jsxs("div", {
          className:
            "w-full h-[7rem] flex items-center justify-between px-10 bg-banner bg-cover bg-center bg-no-repeat rounded-[.3125rem]",
          children: [
            i.jsxs("div", {
              className: "flex items-center gap-5",
              children: [
                i.jsxs("div", {
                  className:
                    "size-[4.5rem] rounded-full border-[2px] border-[#ff4848ff] relative bg-center bg-cover bg-no-repeat group cursor-pointer",
                  style: { backgroundImage: `url(${d})` },
                  children: [
                    i.jsx(y9, { currentAvatar: d }),
                    i.jsx("p", {
                      className:
                        "text-[#171918] text-[.625rem] font-extrabold bg-[#ff4848ff] left-1/2 -translate-x-1/2 top-[4rem] absolute px-2.5 h-[1.125rem] flex items-center justify-center rounded",
                      children: "PREMIUM",
                    }),
                  ],
                }),
                i.jsxs("div", {
                  children: [
                    i.jsx("small", {
                      className: "text-white/45 text-xs font-medium",
                      children: "ORGANIZAÇÃO",
                    }),
                    i.jsx("p", {
                      className: "text-white text-lg font-extrabold uppercase",
                      children: m,
                    }),
                  ],
                }),
              ],
            }),
            i.jsxs("div", {
              className: "flex items-center gap-2",
              children: [
                i.jsxs("button", {
                  onClick: () => s("/"),
                  className: ne(
                    "h-8 border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4 flex items-center justify-center gap-2 text-white/45 text-sm font-bold",
                    a === "/" && "!bg-[#ff4848ff] !text-[#151716]",
                  ),
                  children: [
                    i.jsx("svg", {
                      width: ".625rem",
                      height: ".625rem",
                      viewBox: "0 0 10 10",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: i.jsx("path", {
                        d: "M4.54545 2.27273C4.54545 2.72223 4.41216 3.16164 4.16243 3.53539C3.9127 3.90914 3.55775 4.20044 3.14246 4.37245C2.72718 4.54447 2.27021 4.58948 1.82934 4.50178C1.38848 4.41409 0.983514 4.19763 0.665667 3.87979C0.347821 3.56194 0.131364 3.15698 0.0436708 2.71611C-0.0440228 2.27525 0.000984736 1.81828 0.173002 1.40299C0.345019 0.987706 0.63632 0.632755 1.01007 0.383024C1.38382 0.133294 1.82322 1.01178e-06 2.27273 1.01178e-06C2.87549 1.01178e-06 3.45357 0.239448 3.87979 0.665667C4.30601 1.09189 4.54545 1.66996 4.54545 2.27273ZM7.72727 4.54545C8.17677 4.54545 8.61618 4.41216 8.98993 4.16243C9.36368 3.9127 9.65498 3.55775 9.827 3.14246C9.99901 2.72718 10.044 2.27021 9.95633 1.82934C9.86864 1.38848 9.65218 0.983514 9.33433 0.665667C9.01649 0.347821 8.61152 0.131364 8.17066 0.0436708C7.72979 -0.0440228 7.27282 0.000984736 6.85754 0.173002C6.44225 0.345019 6.0873 0.63632 5.83757 1.01007C5.58784 1.38382 5.45455 1.82322 5.45455 2.27273C5.45455 2.87549 5.69399 3.45357 6.12021 3.87979C6.54643 4.30601 7.12451 4.54545 7.72727 4.54545ZM2.27273 5.45455C1.82322 5.45455 1.38382 5.58784 1.01007 5.83757C0.63632 6.0873 0.345019 6.44225 0.173002 6.85754C0.000984736 7.27282 -0.0440228 7.72979 0.0436708 8.17066C0.131364 8.61152 0.347821 9.01649 0.665667 9.33433C0.983514 9.65218 1.38848 9.86864 1.82934 9.95633C2.27021 10.044 2.72718 9.99901 3.14246 9.827C3.55775 9.65498 3.9127 9.36368 4.16243 8.98993C4.41216 8.61618 4.54545 8.17677 4.54545 7.72727C4.54545 7.12451 4.30601 6.54643 3.87979 6.12021C3.45357 5.69399 2.87549 5.45455 2.27273 5.45455ZM7.72727 5.45455C7.27777 5.45455 6.83836 5.58784 6.46461 5.83757C6.09086 6.0873 5.79956 6.44225 5.62755 6.85754C5.45553 7.27282 5.41052 7.72979 5.49821 8.17066C5.58591 8.61152 5.80236 9.01649 6.12021 9.33433C6.43806 9.65218 6.84302 9.86864 7.28388 9.95633C7.72475 10.044 8.18172 9.99901 8.59701 9.827C9.01229 9.65498 9.36724 9.36368 9.61697 8.98993C9.86671 8.61618 10 8.17677 10 7.72727C10 7.12451 9.76055 6.54643 9.33433 6.12021C8.90811 5.69399 8.33004 5.45455 7.72727 5.45455Z",
                        fill: a === "/" ? "#151716" : "white",
                        "fill-opacity": a === "/" ? 1 : 0.45,
                      }),
                    }),
                    "INÍCIO",
                  ],
                }),
                i.jsxs("button", {
                  onClick: () => s("/members"),
                  className: ne(
                    "h-8 border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4 flex items-center justify-center gap-2 text-white/45 text-sm font-bold",
                    a === "/members" && "!bg-[#ff4848ff] !text-[#151716]",
                  ),
                  children: [
                    i.jsx("svg", {
                      width: ".625rem",
                      height: ".625rem",
                      viewBox: "0 0 10 10",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: i.jsx("path", {
                        d: "M9.92272 9.38424C9.96571 9.44137 9.99192 9.50935 9.99841 9.58055C10.0049 9.65176 9.99141 9.72336 9.95945 9.78732C9.92749 9.85128 9.87833 9.90506 9.81749 9.94263C9.75665 9.9802 9.68654 10.0001 9.61504 10H0.384602C0.313177 10 0.243162 9.98011 0.182405 9.94257C0.121647 9.90502 0.0725459 9.8513 0.0406036 9.78743C0.00866132 9.72355 -0.00486013 9.65204 0.00155424 9.58091C0.00796861 9.50979 0.0340654 9.44185 0.0769205 9.38472C0.417478 8.92819 0.871614 8.56874 1.39418 8.3421C1.10774 8.0807 0.907032 7.73882 0.818408 7.36132C0.729783 6.98382 0.757381 6.58835 0.897579 6.22682C1.03778 5.86529 1.28402 5.55459 1.604 5.3355C1.92397 5.11641 2.30272 4.99917 2.69053 4.99917C3.07834 4.99917 3.45708 5.11641 3.77706 5.3355C4.09703 5.55459 4.34328 5.86529 4.48348 6.22682C4.62367 6.58835 4.65127 6.98382 4.56265 7.36132C4.47402 7.73882 4.27332 8.0807 3.98688 8.3421C4.36389 8.50504 4.7065 8.73815 4.99645 9.02901C5.28641 8.73815 5.62902 8.50504 6.00603 8.3421C5.71959 8.0807 5.51888 7.73882 5.43026 7.36132C5.34164 6.98382 5.36923 6.58835 5.50943 6.22682C5.64963 5.86529 5.89588 5.55459 6.21585 5.3355C6.53582 5.11641 6.91457 4.99917 7.30238 4.99917C7.69019 4.99917 8.06894 5.11641 8.38891 5.3355C8.70889 5.55459 8.95513 5.86529 9.09533 6.22682C9.23553 6.58835 9.26313 6.98382 9.1745 7.36132C9.08588 7.73882 8.88517 8.0807 8.59873 8.3421C9.12372 8.56754 9.58029 8.92691 9.92272 9.38424ZM0.153841 4.92392C0.194246 4.95422 0.240225 4.97627 0.289151 4.9888C0.338077 5.00134 0.388994 5.00411 0.438993 4.99697C0.488991 4.98983 0.537094 4.97291 0.580554 4.94718C0.624013 4.92145 0.661979 4.88741 0.692283 4.84701C0.925142 4.53657 1.22709 4.28461 1.57422 4.11107C1.92134 3.93753 2.30411 3.84718 2.69221 3.84718C3.08031 3.84718 3.46308 3.93753 3.8102 4.11107C4.15733 4.28461 4.45928 4.53657 4.69214 4.84701C4.72796 4.89477 4.77442 4.93354 4.82782 4.96024C4.88122 4.98693 4.94011 5.00083 4.99982 5.00083C5.05953 5.00083 5.11841 4.98693 5.17182 4.96024C5.22522 4.93354 5.27168 4.89477 5.3075 4.84701C5.54036 4.53657 5.84231 4.28461 6.18943 4.11107C6.53656 3.93753 6.91933 3.84718 7.30743 3.84718C7.69553 3.84718 8.0783 3.93753 8.42542 4.11107C8.77255 4.28461 9.0745 4.53657 9.30736 4.84701C9.33769 4.88741 9.37569 4.92144 9.41918 4.94716C9.46267 4.97288 9.51079 4.98978 9.56082 4.9969C9.61084 5.00402 9.66177 5.00122 9.71071 4.98865C9.75965 4.97609 9.80563 4.95401 9.84604 4.92368C9.88644 4.89335 9.92048 4.85536 9.9462 4.81188C9.97192 4.76839 9.98882 4.72027 9.99594 4.67026C10.0031 4.62024 10.0003 4.56931 9.9877 4.52038C9.97513 4.47145 9.95305 4.42547 9.92272 4.38507C9.58215 3.92867 9.128 3.56938 8.60546 3.34294C8.8919 3.08154 9.09261 2.73965 9.18123 2.36216C9.26986 1.98466 9.24226 1.58919 9.10206 1.22766C8.96186 0.866122 8.71562 0.555419 8.39564 0.336329C8.07567 0.117239 7.69692 0 7.30911 0C6.9213 0 6.54255 0.117239 6.22258 0.336329C5.90261 0.555419 5.65636 0.866122 5.51616 1.22766C5.37596 1.58919 5.34837 1.98466 5.43699 2.36216C5.52562 2.73965 5.72632 3.08154 6.01276 3.34294C5.63575 3.50588 5.29314 3.73898 5.00318 4.02984C4.71323 3.73898 4.37062 3.50588 3.99361 3.34294C4.28005 3.08154 4.48075 2.73965 4.56938 2.36216C4.658 1.98466 4.63041 1.58919 4.49021 1.22766C4.35001 0.866122 4.10376 0.555419 3.78379 0.336329C3.46382 0.117239 3.08507 0 2.69726 0C2.30945 0 1.9307 0.117239 1.61073 0.336329C1.29075 0.555419 1.04451 0.866122 0.904309 1.22766C0.764111 1.58919 0.736513 1.98466 0.825138 2.36216C0.913763 2.73965 1.11447 3.08154 1.40091 3.34294C0.875893 3.56857 0.419337 3.9281 0.0769205 4.38555C0.0466165 4.42595 0.0245677 4.47192 0.0120329 4.52084C-0.000501866 4.56976 -0.00327709 4.62067 0.00386562 4.67067C0.0110083 4.72066 0.0279292 4.76875 0.0536619 4.81221C0.0793947 4.85566 0.113436 4.89362 0.153841 4.92392Z",
                        fill: a === "/members" ? "#151716" : "white",
                        "fill-opacity": a === "/members" ? 1 : 0.45,
                      }),
                    }),
                    "MEMBROS",
                  ],
                }),
                i.jsxs("button", {
                  onClick: () => s("/ranking"),
                  className: ne(
                    "h-8 border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4 flex items-center justify-center gap-2 text-white/45 text-sm font-bold",
                    a === "/ranking" && "!bg-[#ff4848ff] !text-[#151716]",
                  ),
                  children: [
                    i.jsx("svg", {
                      width: ".625rem",
                      height: ".625rem",
                      viewBox: "0 0 10 10",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: i.jsx("path", {
                        d: "M8 1.08526V0H2V1.08526H0V2.63158C0 3.96053 0.9445 5.05158 2.162 5.22737C2.33648 5.76563 2.64582 6.24429 3.05735 6.61281C3.46887 6.98133 3.9673 7.22603 4.5 7.32105V7.89474C4.5 8.17391 4.39464 8.44165 4.20711 8.63906C4.01957 8.83647 3.76522 8.94737 3.5 8.94737H3V10H7V8.94737H6.5C6.23478 8.94737 5.98043 8.83647 5.79289 8.63906C5.60536 8.44165 5.5 8.17391 5.5 7.89474V7.32105C6.0327 7.22603 6.53113 6.98133 6.94265 6.61281C7.35418 6.24429 7.66352 5.76563 7.838 5.22737C9.0555 5.05158 10 3.96053 10 2.63158V1.08526H8ZM1 2.63158V2.13789H2V4.12C1.70758 4.01117 1.4544 3.80961 1.27532 3.54305C1.09623 3.2765 1.00004 2.95806 1 2.63158ZM9 2.63158C8.99933 2.95797 8.90291 3.27617 8.72391 3.54268C8.54492 3.8092 8.29209 4.01101 8 4.12053V2.13789H9V2.63158Z",
                        fill: a === "/ranking" ? "#151716" : "white",
                        "fill-opacity": a === "/ranking" ? 1 : 0.45,
                      }),
                    }),
                    "RANKING",
                  ],
                }),
                i.jsxs("button", {
                  onClick: () => s("/goals"),
                  className: ne(
                    "h-8 border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4 flex items-center justify-center gap-2 text-white/45 text-sm font-bold",
                    a === "/goals" && "!bg-[#ff4848ff] !text-[#151716]",
                  ),
                  children: [
                    i.jsx("svg", {
                      width: ".5rem",
                      height: ".625rem",
                      viewBox: "0 0 8 10",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: i.jsx("path", {
                        d: "M5.01333 1.17647L4.8 0H0V10H1.06667V5.88235H4.05333L4.26667 7.05882H8V1.17647H5.01333Z",
                        fill: a === "/goals" ? "#151716" : "white",
                        "fill-opacity": a === "/goals" ? 1 : 0.45,
                      }),
                    }),
                    "METAS",
                  ],
                }),
                i.jsxs("button", {
                  onClick: () => s("/bank"),
                  className: ne(
                    "h-8 border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4 flex items-center justify-center gap-2 text-white/45 text-sm font-bold",
                    a === "/bank" && "!bg-[#ff4848ff] !text-[#151716]",
                  ),
                  children: [
                    i.jsx("svg", {
                      width: ".5625rem",
                      height: ".625rem",
                      viewBox: "0 0 9 10",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: i.jsx("path", {
                        d: "M4.5 0L0 2.38095V3.33333H9V2.38095M6.63158 4.28571V7.61905H8.05263V4.28571M0 10H9V8.57143H0M3.78947 4.28571V7.61905H5.21053V4.28571M0.947368 4.28571V7.61905H2.36842V4.28571H0.947368Z",
                        fill: a === "/bank" ? "#151716" : "white",
                        "fill-opacity": a === "/bank" ? 1 : 0.45,
                      }),
                    }),
                    "BANCO",
                  ],
                }),
                i.jsxs("button", {
                  onClick: () => s("/partners"),
                  className: ne(
                    "h-8 border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4 flex items-center justify-center gap-2 text-white/45 text-sm font-bold",
                    a === "/partners" && "!bg-[#ff4848ff] !text-[#151716]",
                  ),
                  children: [
                    i.jsx("svg", {
                      width: ".625rem",
                      height: ".625rem",
                      viewBox: "0 0 10 10",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: i.jsx("path", {
                        d: "M4.47812 1.87461H6.04375L7.76073 0.154209C7.80925 0.105346 7.86697 0.0665615 7.93056 0.0400941C7.99416 0.0136267 8.06237 0 8.13126 0C8.20016 0 8.26837 0.0136267 8.33197 0.0400941C8.39556 0.0665615 8.45328 0.105346 8.5018 0.154209L9.84824 1.50446C9.94544 1.60214 10 1.73427 10 1.872C10 2.00973 9.94544 2.14186 9.84824 2.23954L8.65314 3.43861H4.47812V4.48127C4.47812 4.61954 4.42314 4.75214 4.32527 4.84991C4.2274 4.94768 4.09466 5.00261 3.95624 5.00261C3.81783 5.00261 3.68509 4.94768 3.58722 4.84991C3.48935 4.75214 3.43437 4.61954 3.43437 4.48127V2.91727C3.43437 2.64074 3.54433 2.37554 3.74008 2.18C3.93582 1.98446 4.2013 1.87461 4.47812 1.87461ZM1.34686 4.48127V6.56661L0.151758 7.76046C0.054558 7.85814 0 7.99027 0 8.128C0 8.26573 0.054558 8.39786 0.151758 8.49554L1.4982 9.84579C1.54672 9.89466 1.60444 9.93344 1.66803 9.95991C1.73163 9.98637 1.79984 10 1.86873 10C1.93763 10 2.00584 9.98637 2.06944 9.95991C2.13303 9.93344 2.19075 9.89466 2.23927 9.84579L4.47812 7.60927H6.56563C6.70404 7.60927 6.83678 7.55435 6.93466 7.45658C7.03253 7.35881 7.08751 7.2262 7.08751 7.08794V6.56661H7.60939C7.7478 6.56661 7.88054 6.51168 7.97841 6.41391C8.07628 6.31614 8.13126 6.18354 8.13126 6.04527V5.52394H8.65314C8.79155 5.52394 8.92429 5.46901 9.02217 5.37124C9.12004 5.27348 9.17502 5.14087 9.17502 5.00261V4.48127H5.52188V5.00261C5.52188 5.27914 5.41191 5.54434 5.21617 5.73988C5.02043 5.93542 4.75494 6.04527 4.47812 6.04527H3.43437C3.15755 6.04527 2.89206 5.93542 2.69632 5.73988C2.50058 5.54434 2.39061 5.27914 2.39061 5.00261V3.43861L1.34686 4.48127Z",
                        fill: a === "/partners" ? "#151716" : "white",
                        "fill-opacity": a === "/partners" ? 1 : 0.45,
                      }),
                    }),
                    "PARCERIAS",
                  ],
                }),
                i.jsxs("button", {
                  onClick: () => s("/settings"),
                  className: ne(
                    "h-8 border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4 flex items-center justify-center gap-2 text-white/45 text-sm font-bold",
                    a === "/settings" && "!bg-[#ff4848ff] !text-[#151716]",
                  ),
                  children: [
                    i.jsx("svg", {
                      width: ".625rem",
                      height: ".625rem",
                      viewBox: "0 0 10 10",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: i.jsx("path", {
                        d: "M9.90811 4.00045C9.89816 3.94631 9.8775 3.8951 9.84754 3.85031C9.81757 3.80553 9.77901 3.76821 9.73446 3.74091L8.40286 2.92381L8.3975 1.30787C8.39734 1.25222 8.38596 1.19727 8.36415 1.14681C8.34234 1.09636 8.31061 1.0516 8.27117 1.01564C7.78814 0.575701 7.23189 0.23856 6.632 0.0221406C6.58476 0.00492378 6.53469 -0.00144772 6.48503 0.0034365C6.43536 0.00832072 6.38719 0.0243524 6.34363 0.0504988L5.00042 0.858947L3.65588 0.0490568C3.61229 0.0227632 3.56406 0.00661045 3.51431 0.00164286C3.46456 -0.00332473 3.41439 0.00300333 3.36706 0.020218C2.76753 0.238027 2.21189 0.576473 1.72968 1.01756C1.69029 1.05347 1.6586 1.09815 1.63679 1.14852C1.61498 1.19888 1.60357 1.25374 1.60335 1.30931L1.59665 2.92669L0.265049 3.74379C0.220499 3.7711 0.181932 3.80841 0.151969 3.8532C0.122005 3.89798 0.101348 3.94919 0.091401 4.00334C-0.030467 4.66273 -0.030467 5.34152 0.091401 6.00091C0.101348 6.05505 0.122005 6.10626 0.151969 6.15105C0.181932 6.19583 0.220499 6.23315 0.265049 6.26046L1.59665 7.07756L1.60201 8.69397C1.60217 8.74962 1.61355 8.80457 1.63536 8.85503C1.65717 8.90548 1.68889 8.95024 1.72834 8.98621C2.21137 9.42614 2.76762 9.76328 3.3675 9.9797C3.41475 9.99692 3.46481 10.0033 3.51448 9.99841C3.56415 9.99352 3.61231 9.97749 3.65588 9.95134L5.00042 9.14049L6.34497 9.95038C6.39818 9.9823 6.45815 9.99886 6.51906 9.99845C6.55807 9.99843 6.59681 9.99162 6.63379 9.97826C7.23316 9.76055 7.78877 9.42245 8.27117 8.98188C8.31056 8.94597 8.34225 8.90129 8.36405 8.85092C8.38586 8.80056 8.39727 8.7457 8.3975 8.69013L8.4042 7.07275L9.7358 6.25565C9.78035 6.22834 9.81891 6.19103 9.84888 6.14624C9.87884 6.10146 9.8995 6.05025 9.90944 5.9961C10.0306 5.33724 10.0302 4.65913 9.90811 4.00045ZM5.00042 6.92231C4.64727 6.92231 4.30204 6.80955 4.0084 6.59829C3.71477 6.38704 3.4859 6.08677 3.35076 5.73546C3.21561 5.38416 3.18025 4.99759 3.24915 4.62464C3.31804 4.2517 3.4881 3.90912 3.73782 3.64024C3.98754 3.37137 4.3057 3.18826 4.65207 3.11407C4.99844 3.03989 5.35746 3.07796 5.68374 3.22348C6.01001 3.369 6.28888 3.61542 6.48508 3.93159C6.68129 4.24776 6.78601 4.61947 6.78601 4.99972C6.78601 5.50962 6.59789 5.99864 6.26302 6.35919C5.92816 6.71975 5.47399 6.92231 5.00042 6.92231Z",
                        fill: a === "/settings" ? "#151716" : "white",
                        "fill-opacity": a === "/settings" ? 1 : 0.45,
                      }),
                    }),
                    "CONFIGURAÇÕES",
                  ],
                }),
              ],
            }),
          ],
        }),
        i.jsxs("div", {
          className: "w-full flex items-center gap-3",
          children: [
            i.jsxs("div", {
              className:
                "flex-1 h-[4.5rem] rounded-[.3125rem] border-[.0625rem] border-white/5 bg-white/[.01] flex items-center gap-4 px-4",
              children: [
                i.jsxs("svg", {
                  width: "3.125rem",
                  height: "2.75rem",
                  viewBox: "0 0 50 44",
                  fill: "none",
                  xmlns: "http://www.w3.org/2000/svg",
                  children: [
                    i.jsx("path", {
                      d: "M0 22L12.5 1.1059e-06L37.5 0L50 22L37.5 44L12.5 44L0 22Z",
                      fill: "#ff4848ff",
                    }),
                    i.jsx("path", {
                      d: "M32.8763 29.0148C32.9451 29.1062 32.9871 29.215 32.9975 29.3289C33.0078 29.4428 32.9863 29.5574 32.9351 29.6597C32.884 29.762 32.8053 29.8481 32.708 29.9082C32.6106 29.9683 32.4985 30.0001 32.3841 30H17.6154C17.5011 30 17.3891 29.9682 17.2918 29.9081C17.1946 29.848 17.1161 29.7621 17.065 29.6599C17.0139 29.5577 16.9922 29.4433 17.0025 29.3295C17.0127 29.2157 17.0545 29.107 17.1231 29.0155C17.668 28.2851 18.3946 27.71 19.2307 27.3474C18.7724 26.9291 18.4513 26.3821 18.3095 25.7781C18.1677 25.1741 18.2118 24.5414 18.4361 23.9629C18.6604 23.3845 19.0544 22.8873 19.5664 22.5368C20.0784 22.1862 20.6843 21.9987 21.3048 21.9987C21.9253 21.9987 22.5313 22.1862 23.0433 22.5368C23.5553 22.8873 23.9492 23.3845 24.1736 23.9629C24.3979 24.5414 24.442 25.1741 24.3002 25.7781C24.1584 26.3821 23.8373 26.9291 23.379 27.3474C23.9822 27.6081 24.5304 27.981 24.9943 28.4464C25.4583 27.981 26.0064 27.6081 26.6097 27.3474C26.1513 26.9291 25.8302 26.3821 25.6884 25.7781C25.5466 25.1741 25.5908 24.5414 25.8151 23.9629C26.0394 23.3845 26.4334 22.8873 26.9454 22.5368C27.4573 22.1862 28.0633 21.9987 28.6838 21.9987C29.3043 21.9987 29.9103 22.1862 30.4223 22.5368C30.9342 22.8873 31.3282 23.3845 31.5525 23.9629C31.7768 24.5414 31.821 25.1741 31.6792 25.7781C31.5374 26.3821 31.2163 26.9291 30.758 27.3474C31.598 27.7081 32.3285 28.2831 32.8763 29.0148ZM17.2461 21.8783C17.3108 21.9268 17.3844 21.962 17.4626 21.9821C17.5409 22.0021 17.6224 22.0066 17.7024 21.9952C17.7824 21.9837 17.8594 21.9567 17.9289 21.9155C17.9984 21.8743 18.0592 21.8199 18.1077 21.7552C18.4802 21.2585 18.9633 20.8554 19.5187 20.5777C20.0741 20.3 20.6866 20.1555 21.3075 20.1555C21.9285 20.1555 22.5409 20.3 23.0963 20.5777C23.6517 20.8554 24.1348 21.2585 24.5074 21.7552C24.5647 21.8316 24.6391 21.8937 24.7245 21.9364C24.81 21.9791 24.9042 22.0013 24.9997 22.0013C25.0952 22.0013 25.1895 21.9791 25.2749 21.9364C25.3604 21.8937 25.4347 21.8316 25.492 21.7552C25.8646 21.2585 26.3477 20.8554 26.9031 20.5777C27.4585 20.3 28.0709 20.1555 28.6919 20.1555C29.3128 20.1555 29.9253 20.3 30.4807 20.5777C31.0361 20.8554 31.5192 21.2585 31.8918 21.7552C31.9403 21.8199 32.0011 21.8743 32.0707 21.9155C32.1403 21.9566 32.2173 21.9836 32.2973 21.995C32.3773 22.0064 32.4588 22.0019 32.5371 21.9818C32.6154 21.9617 32.689 21.9264 32.7537 21.8779C32.8183 21.8294 32.8728 21.7686 32.9139 21.699C32.9551 21.6294 32.9821 21.5524 32.9935 21.4724C33.0049 21.3924 33.0004 21.3109 32.9803 21.2326C32.9602 21.1543 32.9249 21.0808 32.8763 21.0161C32.3314 20.2859 31.6048 19.711 30.7687 19.3487C31.227 18.9305 31.5482 18.3834 31.69 17.7795C31.8318 17.1755 31.7876 16.5427 31.5633 15.9642C31.339 15.3858 30.945 14.8887 30.433 14.5381C29.9211 14.1876 29.3151 14 28.6946 14C28.0741 14 27.4681 14.1876 26.9561 14.5381C26.4442 14.8887 26.0502 15.3858 25.8259 15.9642C25.6015 16.5427 25.5574 17.1755 25.6992 17.7795C25.841 18.3834 26.1621 18.9305 26.6204 19.3487C26.0172 19.6094 25.469 19.9824 25.0051 20.4477C24.5412 19.9824 23.993 19.6094 23.3898 19.3487C23.8481 18.9305 24.1692 18.3834 24.311 17.7795C24.4528 17.1755 24.4086 16.5427 24.1843 15.9642C23.96 15.3858 23.566 14.8887 23.0541 14.5381C22.5421 14.1876 21.9361 14 21.3156 14C20.6951 14 20.0891 14.1876 19.5772 14.5381C19.0652 14.8887 18.6712 15.3858 18.4469 15.9642C18.2226 16.5427 18.1784 17.1755 18.3202 17.7795C18.462 18.3834 18.7831 18.9305 19.2415 19.3487C18.4014 19.7097 17.6709 20.285 17.1231 21.0169C17.0746 21.0815 17.0393 21.1551 17.0193 21.2334C16.9992 21.3116 16.9948 21.3931 17.0062 21.4731C17.0176 21.5531 17.0447 21.63 17.0859 21.6995C17.127 21.7691 17.1815 21.8298 17.2461 21.8783Z",
                      fill: "#171918",
                    }),
                  ],
                }),
                i.jsxs("div", {
                  children: [
                    i.jsx("small", {
                      className: "text-white/65 text-xs font-medium",
                      children: "ORGANIZAÇÃO",
                    }),
                    i.jsx("p", {
                      className: "text-white text-sm font-bold uppercase",
                      children: m,
                    }),
                  ],
                }),
              ],
            }),
            i.jsxs("div", {
              className:
                "flex-1 h-[4.5rem] rounded-[.3125rem] border-[.0625rem] border-white/5 bg-white/[.01] flex items-center gap-4 px-4",
              children: [
                i.jsxs("svg", {
                  width: "3.1875rem",
                  height: "2.75rem",
                  viewBox: "0 0 51 44",
                  fill: "none",
                  xmlns: "http://www.w3.org/2000/svg",
                  children: [
                    i.jsx("path", {
                      d: "M0.5 22L13 1.1059e-06L38 0L50.5 22L38 44L13 44L0.5 22Z",
                      fill: "#ff4848ff",
                    }),
                    i.jsx("path", {
                      d: "M22.5 29.9774V24.6774C21.9 24.3774 21.5 23.6774 21.5 22.9774V18.9774C21.5 18.2774 21.9 17.6774 22.5 17.2774V16.9774C22.5 15.8774 21.6 14.9774 20.5 14.9774C19.4 14.9774 18.5 15.8774 18.5 16.9774C18.5 18.0774 19.4 18.9774 20.5 18.9774H18.5C18 18.9774 17.5 19.4774 17.5 19.9774V23.9774C17.5 24.4774 18 24.9774 18.5 24.9774V29.9774H22.5ZM32.5 18.9774H30.5C31.6 18.9774 32.5 18.0774 32.5 16.9774C32.5 15.8774 31.6 14.9774 30.5 14.9774C29.4 14.9774 28.5 15.8774 28.5 16.9774V17.2774C29.1 17.6774 29.5 18.2774 29.5 18.9774V22.9774C29.5 23.6774 29.1 24.3774 28.5 24.6774V29.9774H32.5V24.9774C33 24.9774 33.5 24.4774 33.5 23.9774V19.9774C33.5 19.4774 33 18.9774 32.5 18.9774ZM27.5 15.9774C27.506 16.2437 27.4588 16.5086 27.361 16.7564C27.2633 17.0042 27.117 17.23 26.9308 17.4205C26.7446 17.6111 26.5222 17.7625 26.2767 17.8658C26.0311 17.9692 25.7674 18.0225 25.501 18.0226C25.2346 18.0226 24.9709 17.9695 24.7253 17.8662C24.4797 17.763 24.2572 17.6117 24.0709 17.4213C23.8846 17.2308 23.7382 17.0051 23.6404 16.7573C23.5425 16.5095 23.4951 16.2447 23.501 15.9784C23.5126 15.4558 23.7282 14.9585 24.1018 14.593C24.4755 14.2275 24.9773 14.0227 25.5 14.0226C26.0227 14.0225 26.5247 14.2269 26.8985 14.5923C27.2723 14.9576 27.4882 15.4548 27.5 15.9774Z",
                      fill: "#171918",
                    }),
                    i.jsx("path", {
                      d: "M27.5 17.9774H23.5C23 17.9774 22.5 18.4774 22.5 18.9774V22.9774C22.5 23.4774 23 23.9774 23.5 23.9774V29.9774H27.5V23.9774C28 23.9774 28.5 23.4774 28.5 22.9774V18.9774C28.5 18.4774 28 17.9774 27.5 17.9774Z",
                      fill: "#171918",
                    }),
                  ],
                }),
                i.jsxs("div", {
                  children: [
                    i.jsx("small", {
                      className: "text-white/65 text-xs font-medium",
                      children: "MEMBROS",
                    }),
                    i.jsxs("p", {
                      className: "text-[#ff4848ff] text-sm font-bold",
                      children: [v, "/", y],
                    }),
                  ],
                }),
              ],
            }),
            i.jsxs("div", {
              className:
                "flex-1 h-[4.5rem] rounded-[.3125rem] border-[.0625rem] border-white/5 bg-white/[.01] flex items-center gap-4 px-4",
              children: [
                i.jsxs("svg", {
                  width: "3.125rem",
                  height: "2.75rem",
                  viewBox: "0 0 50 44",
                  fill: "none",
                  xmlns: "http://www.w3.org/2000/svg",
                  children: [
                    i.jsx("path", {
                      d: "M0 22L12.5 1.1059e-06L37.5 0L50 22L37.5 44L12.5 44L0 22Z",
                      fill: "#ff4848ff",
                    }),
                    i.jsx("path", {
                      d: "M31 22C31 18.6863 28.3137 16 25 16C21.6863 16 19 18.6863 19 22C19 25.3137 21.6863 28 25 28V29C21.134 29 18 25.866 18 22C18 18.134 21.134 15 25 15C28.866 15 32 18.134 32 22C32 25.866 28.866 29 25 29V28C28.3137 28 31 25.3137 31 22Z",
                      fill: "#171918",
                    }),
                    i.jsx("path", {
                      d: "M29 22C29 24.2091 27.2091 26 25 26C22.7909 26 21 24.2091 21 22C21 19.7909 22.7909 18 25 18C27.2091 18 29 19.7909 29 22Z",
                      fill: "#171918",
                    }),
                  ],
                }),
                i.jsxs("div", {
                  children: [
                    i.jsx("small", {
                      className: "text-white/65 text-xs font-medium",
                      children: "ON-LINE",
                    }),
                    i.jsxs("p", {
                      className: "text-[#ff4848ff] text-sm font-bold",
                      children: [x, " MEMBROS"],
                    }),
                  ],
                }),
              ],
            }),
            i.jsxs("div", {
              className:
                "flex-1 h-[4.5rem] rounded-[.3125rem] border-[.0625rem] border-white/5 bg-white/[.01] flex items-center gap-4 px-4",
              children: [
                i.jsxs("svg", {
                  width: "3.1875rem",
                  height: "2.75rem",
                  viewBox: "0 0 51 44",
                  fill: "none",
                  xmlns: "http://www.w3.org/2000/svg",
                  children: [
                    i.jsx("path", {
                      d: "M0.5 22L13 1.1059e-06L38 0L50.5 22L38 44L13 44L0.5 22Z",
                      fill: "#ff4848ff",
                    }),
                    i.jsx("path", {
                      d: "M25.5 14L18.5 17.8095V19.3333H32.5V17.8095M28.8158 20.8571V26.1905H31.0263V20.8571M18.5 30H32.5V27.7143H18.5M24.3947 20.8571V26.1905H26.6053V20.8571M19.9737 20.8571V26.1905H22.1842V20.8571H19.9737Z",
                      fill: "#171918",
                    }),
                  ],
                }),
                i.jsxs("div", {
                  children: [
                    i.jsx("small", {
                      className: "text-white/65 text-xs font-medium",
                      children: "CAIXA",
                    }),
                    i.jsx("p", {
                      className: "text-[#ff4848ff] text-sm font-bold",
                      children: h.toLocaleString("pt-br", {
                        style: "currency",
                        currency: "BRL",
                      }),
                    }),
                  ],
                }),
              ],
            }),
          ],
        }),
        i.jsx("div", {
          className: "w-full flex-1 overflow-hidden",
          children: r,
        }),
      ],
    })
  );
}
function En({ status: r }) {
  return i.jsx(i.Fragment, {
    children:
      r === 1
        ? i.jsxs("svg", {
            width: "3.625rem",
            height: "1.75rem",
            viewBox: "0 0 58 28",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
              i.jsx("path", {
                d: "M13.9286 14L21.4286 0.500001L36.4286 0.5L43.9286 14L36.4286 27.5L21.4286 27.5L13.9286 14Z",
                fill: "#67C32E",
                "fill-opacity": "0.2",
              }),
              i.jsx("path", {
                "fill-rule": "evenodd",
                "clip-rule": "evenodd",
                d: "M34.5685 9.98139C34.7325 10.1455 34.8247 10.368 34.8247 10.6C34.8247 10.832 34.7325 11.0546 34.5685 11.2186L28.0101 17.7771C27.9234 17.8638 27.8205 17.9325 27.7073 17.9794C27.594 18.0264 27.4726 18.0505 27.35 18.0505C27.2275 18.0505 27.1061 18.0264 26.9928 17.9794C26.8796 17.9325 26.7767 17.8638 26.69 17.7771L23.4315 14.5191C23.3479 14.4384 23.2813 14.3419 23.2354 14.2351C23.1895 14.1284 23.1654 14.0136 23.1644 13.8974C23.1634 13.7812 23.1855 13.666 23.2295 13.5584C23.2735 13.4509 23.3385 13.3532 23.4206 13.271C23.5028 13.1889 23.6005 13.1239 23.708 13.0799C23.8156 13.0359 23.9308 13.0138 24.047 13.0148C24.1632 13.0158 24.278 13.0399 24.3847 13.0858C24.4915 13.1317 24.588 13.1983 24.6687 13.2819L27.3497 15.9629L33.3307 9.98139C33.4119 9.90008 33.5084 9.83558 33.6146 9.79157C33.7208 9.74757 33.8346 9.72491 33.9496 9.72491C34.0645 9.72491 34.1784 9.74757 34.2846 9.79157C34.3908 9.83558 34.4872 9.90008 34.5685 9.98139Z",
                fill: "#67C32E",
              }),
            ],
          })
        : r === 2
          ? i.jsxs("svg", {
              width: "3.6875rem",
              height: "1.75rem",
              viewBox: "0 0 59 28",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: [
                i.jsx("path", {
                  d: "M14.7857 14L22.2857 0.500001L37.2857 0.5L44.7857 14L37.2857 27.5L22.2857 27.5L14.7857 14Z",
                  fill: "#C33C2E",
                  "fill-opacity": "0.2",
                }),
                i.jsx("path", {
                  "fill-rule": "evenodd",
                  "clip-rule": "evenodd",
                  d: "M30.0057 15.346L33.3733 18.7098C33.552 18.8883 33.7944 18.9886 34.0471 18.9886C34.2998 18.9886 34.5422 18.8883 34.7209 18.7098C34.8996 18.5313 35 18.2893 35 18.0368C35 17.7844 34.8996 17.5423 34.7209 17.3638L31.352 14L34.7203 10.6362C34.8087 10.5478 34.8789 10.4429 34.9267 10.3274C34.9746 10.212 34.9992 10.0882 34.9991 9.96327C34.9991 9.83831 34.9744 9.71458 34.9265 9.59914C34.8786 9.4837 34.8084 9.37882 34.72 9.29048C34.6315 9.20214 34.5264 9.13207 34.4108 9.08428C34.2953 9.03648 34.1714 9.0119 34.0463 9.01193C33.9212 9.01196 33.7973 9.0366 33.6817 9.08445C33.5662 9.1323 33.4611 9.20241 33.3727 9.2908L30.0057 12.6546L26.638 9.2908C26.5502 9.19988 26.4451 9.12734 26.3289 9.07742C26.2128 9.0275 26.0878 9.0012 25.9613 9.00004C25.8348 8.99888 25.7094 9.0229 25.5923 9.07068C25.4752 9.11847 25.3688 9.18907 25.2793 9.27837C25.1898 9.36766 25.1191 9.47386 25.0711 9.59077C25.0232 9.70768 24.999 9.83296 25 9.9593C25.0011 10.0856 25.0273 10.2105 25.0772 10.3266C25.127 10.4427 25.1995 10.5477 25.2905 10.6356L28.6594 14L25.2911 17.3644C25.2002 17.4523 25.1277 17.5573 25.0778 17.6734C25.0279 17.7895 25.0017 17.9144 25.0007 18.0407C24.9996 18.167 25.0238 18.2923 25.0717 18.4092C25.1197 18.5261 25.1905 18.6323 25.28 18.7216C25.3694 18.8109 25.4758 18.8815 25.5929 18.9293C25.71 18.9771 25.8354 19.0011 25.9619 19C26.0884 18.9988 26.2134 18.9725 26.3296 18.9226C26.4458 18.8727 26.5509 18.8001 26.6387 18.7092L30.0057 15.346Z",
                  fill: "#C33C2E",
                }),
              ],
            })
          : i.jsxs("svg", {
              width: "3.6875rem",
              height: "1.75rem",
              viewBox: "0 0 59 28",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: [
                i.jsx("path", {
                  d: "M14.2143 14L21.7143 0.500001L36.7143 0.5L44.2143 14L36.7143 27.5L21.7143 27.5L14.2143 14Z",
                  fill: "#989898",
                  "fill-opacity": "0.2",
                }),
                i.jsx("path", {
                  d: "M36.4194 1L43.6411 14L36.4194 27H22.0092L14.7866 14L22.0092 1H36.4194Z",
                  stroke: "white",
                  "stroke-opacity": "0.15",
                }),
                i.jsx("path", {
                  d: "M31.7859 9.66995C32.54 10.1054 33.1673 10.7302 33.6058 11.4826C34.0442 12.235 34.2786 13.0888 34.2856 13.9596C34.2926 14.8304 34.0721 15.6879 33.6459 16.4473C33.2197 17.2067 32.6025 17.8416 31.8555 18.2891C31.1085 18.7367 30.2575 18.9814 29.3869 18.999C28.5162 19.0166 27.6561 18.8065 26.8916 18.3896C26.1271 17.9726 25.4847 17.3632 25.0281 16.6217C24.5715 15.8802 24.3165 15.0323 24.2883 14.1619L24.2858 13.9999L24.2883 13.8379C24.3163 12.9744 24.5675 12.1329 25.0176 11.3954C25.4676 10.658 26.1011 10.0497 26.8562 9.62989C27.6114 9.2101 28.4624 8.99314 29.3263 9.00017C30.1903 9.00719 31.0377 9.23795 31.7859 9.66995ZM29.2858 10.9999C29.1634 11 29.0452 11.0449 28.9536 11.1263C28.8621 11.2077 28.8037 11.3198 28.7893 11.4414L28.7858 11.4999V13.9999L28.7903 14.0654C28.8017 14.1522 28.8357 14.2344 28.8888 14.3039L28.9323 14.3539L30.4323 15.8539L30.4793 15.8949C30.567 15.963 30.6749 15.9999 30.7858 15.9999C30.8968 15.9999 31.0047 15.963 31.0924 15.8949L31.1394 15.8534L31.1809 15.8064C31.2489 15.7188 31.2858 15.6109 31.2858 15.4999C31.2858 15.389 31.2489 15.2811 31.1809 15.1934L31.1394 15.1464L29.7858 13.7924V11.4999L29.7823 11.4414C29.768 11.3198 29.7095 11.2077 29.618 11.1263C29.5265 11.0449 29.4083 11 29.2858 10.9999Z",
                  fill: "#989898",
                }),
              ],
            }),
  });
}
function N9({ rankingPosition: r, status: s, name: a }) {
  return i.jsxs("div", {
    className:
      "w-[27.3125rem] h-[12.125rem] bg-white/[.01] border-[.0625rem] border-white/5 rounded-[.3125rem] p-4 flex flex-col gap-3",
    children: [
      i.jsxs("div", {
        className: "w-full flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".625rem",
            height: ".6875rem",
            viewBox: "0 0 10 11",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M8 1.58526V0.5H2V1.58526H0V3.13158C0 4.46053 0.9445 5.55158 2.162 5.72737C2.33648 6.26563 2.64582 6.74429 3.05735 7.11281C3.46887 7.48133 3.9673 7.72603 4.5 7.82105V8.39474C4.5 8.67391 4.39464 8.94165 4.20711 9.13906C4.01957 9.33647 3.76522 9.44737 3.5 9.44737H3V10.5H7V9.44737H6.5C6.23478 9.44737 5.98043 9.33647 5.79289 9.13906C5.60536 8.94165 5.5 8.67391 5.5 8.39474V7.82105C6.0327 7.72603 6.53113 7.48133 6.94265 7.11281C7.35418 6.74429 7.66352 6.26563 7.838 5.72737C9.0555 5.55158 10 4.46053 10 3.13158V1.58526H8ZM1 3.13158V2.63789H2V4.62C1.70758 4.51117 1.4544 4.30961 1.27532 4.04305C1.09623 3.7765 1.00004 3.45806 1 3.13158ZM9 3.13158C8.99933 3.45797 8.90291 3.77617 8.72391 4.04268C8.54492 4.3092 8.29209 4.51101 8 4.62053V2.63789H9V3.13158Z",
              fill: "white",
              "fill-opacity": "0.25",
            }),
          }),
          i.jsx("h2", {
            className: "text-white text-xs font-bold",
            children: "RANKING",
          }),
        ],
      }),
      i.jsxs("div", {
        className: "w-full flex items-center gap-3",
        children: [
          i.jsxs("svg", {
            width: "2.3125rem",
            height: "2rem",
            viewBox: "0 0 37 32",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
              i.jsx("path", {
                d: "M0 16L9.25 8.0429e-07L27.75 0L37 16L27.75 32L9.25 32L0 16Z",
                fill: "white",
                "fill-opacity": "0.08",
              }),
              i.jsx("path", {
                d: "M22.1111 9H15.8889C15.1528 9 14.5528 9.59609 14.5806 10.318C14.5861 10.4629 14.5917 10.6078 14.6 10.75H11.6667C11.2972 10.75 11 11.0426 11 11.4062C11 13.9383 11.9306 15.6992 13.1806 16.8941C14.4111 18.0727 15.9111 18.666 17.0167 18.9668C17.6667 19.1445 18.1111 19.6777 18.1111 20.2137C18.1111 20.7852 17.6389 21.25 17.0583 21.25H16.3333C15.8417 21.25 15.4444 21.641 15.4444 22.125C15.4444 22.609 15.8417 23 16.3333 23H21.6667C22.1583 23 22.5556 22.609 22.5556 22.125C22.5556 21.641 22.1583 21.25 21.6667 21.25H20.9417C20.3611 21.25 19.8889 20.7852 19.8889 20.2137C19.8889 19.6777 20.3306 19.1418 20.9833 18.9668C22.0917 18.666 23.5917 18.0727 24.8222 16.8941C26.0694 15.6992 27 13.9383 27 11.4062C27 11.0426 26.7028 10.75 26.3333 10.75H23.4C23.4083 10.6078 23.4139 10.4656 23.4194 10.318C23.4472 9.59609 22.8472 9 22.1111 9ZM12.3583 12.0625H14.7028C14.9556 14.5262 15.5139 16.1723 16.1444 17.2742C15.4528 16.9734 14.7333 16.5496 14.1111 15.9535C13.2222 15.1031 12.5 13.8754 12.3611 12.0625H12.3583ZM23.8917 15.9535C23.2694 16.5496 22.55 16.9734 21.8583 17.2742C22.4889 16.1723 23.0472 14.5262 23.3 12.0625H25.6444C25.5028 13.8754 24.7806 15.1031 23.8944 15.9535H23.8917Z",
                fill: "#ff4848ff",
              }),
            ],
          }),
          i.jsxs("div", {
            className:
              "flex-1 px-3 h-8 bg-white/[.02] flex items-center justify-between",
            children: [
              i.jsxs("p", {
                className: "text-[#B4B5B5] text-xs font-bold",
                children: [r ?? 0, "°"],
              }),
              i.jsx("div", {
                className: "flex items-center gap-2",
                children: i.jsx("p", {
                  className: "text-white text-xs font-bold",
                  children: a,
                }),
              }),
            ],
          }),
        ],
      }),
      i.jsx("hr", {
        className: "w-full h-[.0625rem] bg-white/5 border-none flex-none",
      }),
      i.jsxs("div", {
        className: "w-full flex flex-col gap-[.6563rem]",
        children: [
          i.jsxs("div", {
            className: "flex items-center",
            children: [
              i.jsx("p", {
                className:
                  "text-white/45 text-xs font-medium text-center flex-1 uppercase",
                children: "Dom",
              }),
              i.jsx("p", {
                className:
                  "text-white/45 text-xs font-medium text-center flex-1 uppercase",
                children: "Seg",
              }),
              i.jsx("p", {
                className:
                  "text-white/45 text-xs font-medium text-center flex-1 uppercase",
                children: "Ter",
              }),
              i.jsx("p", {
                className:
                  "text-white/45 text-xs font-medium text-center flex-1 uppercase",
                children: "Qua",
              }),
              i.jsx("p", {
                className:
                  "text-white/45 text-xs font-medium text-center flex-1 uppercase",
                children: "Qui",
              }),
              i.jsx("p", {
                className:
                  "text-white/45 text-xs font-medium text-center flex-1 uppercase",
                children: "Sex",
              }),
              i.jsx("p", {
                className:
                  "text-white/45 text-xs font-medium text-center flex-1 uppercase",
                children: "Sáb",
              }),
            ],
          }),
          i.jsxs("div", {
            className:
              "w-full h-[2.6875rem] bg-white/[.02] rounded-[.3125rem] flex items-center justify-around",
            children: [
              i.jsx(En, { status: s == null ? void 0 : s[6] }),
              i.jsx(En, { status: s == null ? void 0 : s[0] }),
              i.jsx(En, { status: s == null ? void 0 : s[1] }),
              i.jsx(En, { status: s == null ? void 0 : s[2] }),
              i.jsx(En, { status: s == null ? void 0 : s[3] }),
              i.jsx(En, { status: s == null ? void 0 : s[4] }),
              i.jsx(En, { status: s == null ? void 0 : s[5] }),
            ],
          }),
        ],
      }),
    ],
  });
}
function L9({
  goalsDetails: r,
  isLeader: s,
  onClaimRewards: a,
  onSubmitReward: c,
}) {
  const [d, m] = p.useState(0);
  function x() {
    a(d);
  }
  function h(v) {
    v.key === "Enter" && c(v.currentTarget.value);
  }
  return i.jsxs("div", {
    className:
      "flex-1 h-[12.125rem] bg-white/[.01] border-[.0625rem] border-white/5 rounded-[.3125rem] flex items-center gap-4",
    children: [
      i.jsxs("div", {
        className: "w-[10rem] flex flex-col gap-2.5 my-4 ml-4",
        children: [
          i.jsxs("div", {
            className: "w-full flex items-center gap-2",
            children: [
              i.jsx("svg", {
                width: ".5rem",
                height: ".6875rem",
                viewBox: "0 0 8 11",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                children: i.jsx("path", {
                  d: "M5.01333 1.67647L4.8 0.5H0V10.5H1.06667V6.38235H4.05333L4.26667 7.55882H8V1.67647H5.01333Z",
                  fill: "white",
                  "fill-opacity": "0.25",
                }),
              }),
              i.jsx("h2", {
                className: "text-white text-xs font-bold",
                children: "META DIÁRIA",
              }),
            ],
          }),
          i.jsx("div", {
            className: "w-full flex items-center gap-2.5",
            children: r.rewards.map((v, y) =>
              i.jsxs(
                "div",
                {
                  className:
                    "flex-1 h-[3.5rem] rounded-[.3125rem] overflow-hidden",
                  children: [
                    i.jsx("div", {
                      className:
                        "w-full h-10 bg-white/[.02] flex items-center justify-center",
                      children: i.jsx("img", {
                        src:
                          "http://127.0.0.1/images/" +
                          v.item +
                          ".png",
                        className: "size-10 object-cover",
                      }),
                    }),
                    i.jsx("div", {
                      className:
                        "w-full h-4 bg-white/[.04] flex items-center justify-center",
                      children: i.jsxs("p", {
                        className: "text-white/60 text-[.625rem] font-medium",
                        children: [Math.min(d, v.max), "/", v.max],
                      }),
                    }),
                  ],
                },
                y,
              ),
            ),
          }),
          i.jsx("div", {
            className:
              "w-full h-[1.8125rem] bg-white/[.02] px-2 flex items-center justify-center",
            children: i.jsx("input", {
              type: "range",
              className: "w-full",
              max: r.rewards.reduce((v, y) => (v < y.max ? y.max : v), 0),
              min: 0,
              step: 1,
              value: d,
              onChange: (v) => m(Number(v.target.value)),
              style: {
                "--value": `${(d / r.rewards.reduce((v, y) => (v < y.max ? y.max : v), 0)) * 100}%`,
              },
            }),
          }),
          i.jsx("button", {
            onClick: x,
            className:
              "text-[#151716] text-sm font-bold w-full h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem]",
            children: "ENTREGAR",
          }),
        ],
      }),
      i.jsx("div", {
        className: "h-full w-[.0625rem] bg-white/5 border-none flex-none",
      }),
      i.jsxs("div", {
        className: "w-[12.6875rem] flex flex-col gap-[.9325rem] relative",
        children: [
          i.jsxs("svg", {
            className: "absolute",
            width: "12.5625rem",
            height: "6.3125rem",
            viewBox: "0 0 201 101",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
              i.jsx("mask", {
                id: "mask0_171_67",
                style: { maskType: "alpha" },
                maskUnits: "userSpaceOnUse",
                x: "0",
                y: "0",
                width: "201",
                height: "101",
                children: i.jsx("path", {
                  fillRule: "evenodd",
                  clipRule: "evenodd",
                  d: "M62.1866 7.64813C71.4892 3.76098 81.3033 1.31835 91.2949 0.387551C94.1294 0.1235 96.5 2.41082 96.5 5.25753C96.5 7.93784 94.3885 10.1285 91.7212 10.3916C82.8864 11.2631 74.2111 13.447 65.9803 16.8864C57.6239 20.3783 49.8506 25.1121 42.913 30.9172C40.8518 32.6418 37.7968 32.5996 35.8964 30.6992C33.9045 28.7073 33.9474 25.4525 36.0963 23.6311C43.9191 17.0005 52.7156 11.6058 62.1866 7.64813ZM135.02 16.8864C126.789 13.447 118.114 11.2631 109.279 10.3916C106.611 10.1285 104.5 7.93784 104.5 5.25753C104.5 2.41082 106.871 0.123501 109.705 0.387554C119.697 1.31836 129.511 3.76098 138.813 7.64813C148.284 11.6058 157.081 17.0005 164.904 23.6311C167.053 25.4525 167.095 28.7073 165.104 30.6992C163.203 32.5996 160.148 32.6418 158.087 30.9172C151.149 25.1121 143.376 20.3783 135.02 16.8864ZM170.649 36.4674C168.774 38.3425 168.706 41.3482 170.374 43.4095C175.926 50.2695 180.466 57.9233 183.838 66.1354C187.738 75.6343 190.01 85.72 190.568 95.9621C190.718 98.7193 192.923 100.96 195.661 100.96C198.398 100.96 200.63 98.7197 200.494 95.9616C199.927 84.4056 197.394 73.0207 192.996 62.3083C189.195 53.053 184.059 44.4364 177.766 36.7325C175.964 34.5257 172.664 34.4527 170.649 36.4674ZM30.6255 43.4093C32.2936 41.3481 32.2259 38.3424 30.3509 36.4674C28.3361 34.4527 25.0359 34.5256 23.2336 36.7324C16.9414 44.4363 11.8046 53.053 8.00439 62.3083C3.60608 73.0207 1.07349 84.4056 0.505859 95.9616C0.370361 98.7197 2.60217 100.96 5.33948 100.96C8.07678 100.96 10.2815 98.7193 10.4319 95.9621C10.9902 85.72 13.2617 75.6343 17.162 66.1354C20.5338 57.9233 25.0737 50.2694 30.6255 43.4093Z",
                  fill: "black",
                }),
              }),
              i.jsxs("g", {
                mask: "url(#mask0_171_67)",
                children: [
                  i.jsx("path", {
                    d: "M5.38318 101.04C5.38318 88.4274 7.84582 75.9389 12.6294 64.2884C17.413 52.638 24.4232 42.055 33.2577 33.1425C42.0922 24.2302 52.5778 17.1628 64.1147 12.3419C75.6516 7.52104 88.0152 5.04034 100.5 5.04034C112.985 5.04035 125.348 7.52105 136.885 12.3419C148.422 17.1629 158.908 24.2302 167.742 33.1425C176.577 42.055 183.587 52.638 188.371 64.2884C193.154 75.939 195.617 88.4274 195.617 101.04",
                    stroke: "white",
                    strokeOpacity: "0.03",
                    strokeWidth: "10",
                  }),
                  i.jsx("path", {
                    d: "M5.38318 101.04C5.38318 75.5655 15.415 51.1427 33.2577 33.1425C51.099 15.1438 75.2877 5.04035 100.5 5.04034C125.712 5.04034 149.901 15.1438 167.742 33.1425C185.585 51.1427 195.617 75.5654 195.617 101.04",
                    stroke: "#ff4848ff",
                    strokeWidth: "10",
                    strokeLinecap: "round",
                    pathLength: 100,
                    strokeDasharray: 100,
                    strokeDashoffset: 100 - (r.goalsCurrent / r.goalsMax) * 100,
                  }),
                ],
              }),
            ],
          }),
          i.jsxs("div", {
            className: "flex flex-col items-center mt-[2.5625rem]",
            children: [
              i.jsx("p", {
                className: "text-white/50 text-xs font-medium",
                children: "META DIÁRIA",
              }),
              i.jsxs("p", {
                className: "text-white text-lg font-extrabold",
                children: [
                  r.goalsCurrent.toLocaleString("pt-BR"),
                  "/",
                  r.goalsMax.toLocaleString("pt-BR"),
                ],
              }),
            ],
          }),
          i.jsxs("div", {
            className: "w-full flex flex-col items-center gap-2",
            children: [
              i.jsx("p", {
                className: "text-white/50 text-xs font-medium",
                children: "PARA RESGATAR",
              }),
              s
                ? i.jsx(
                    "input",
                    {
                      type: "text",
                      className:
                        "w-full h-[1.75rem] flex items-center justify-center gap-2 px-4 border-[.0625rem] border-[#ff4848ff] rounded-[.3125rem] bg-transparent text-white text-center text-sm font-semibold focus:outline-none",
                      defaultValue: `R$ ${r.reward.toLocaleString("pt-BR")}`,
                      onKeyUp: h,
                    },
                    r.reward,
                  )
                : i.jsxs("button", {
                    className:
                      "w-full h-[1.75rem] flex items-center justify-center gap-2 px-4 border-[.0625rem] border-[#ff4848ff] rounded-[.3125rem]",
                    children: [
                      i.jsx("p", {
                        className: "text-[#ff4848ff] text-sm font-semibold",
                        children: "R$",
                      }),
                      i.jsx("p", {
                        className: "text-white text-sm font-semibold",
                        children: r.reward.toLocaleString("pt-BR"),
                      }),
                    ],
                  }),
            ],
          }),
        ],
      }),
    ],
  });
}
function E9({ leaders: r }) {
  return i.jsxs("div", {
    className:
      "flex-1 h-[10.6875rem] border-[.0625rem] border-white/5 bg-white/[.01] rounded-[.3125rem] p-4 flex flex-col gap-3",
    children: [
      i.jsx("div", {
        className: "w-full flex items-center justify-between",
        children: i.jsxs("div", {
          className: "flex items-center gap-2",
          children: [
            i.jsx("svg", {
              width: ".6875rem",
              height: ".6875rem",
              viewBox: "0 0 11 11",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: i.jsx("path", {
                d: "M1.22222 8L0 1.125L3.36111 4.25L5.5 0.5L7.63889 4.25L11 1.125L9.77778 8H1.22222ZM9.77778 9.875C9.77778 10.25 9.53333 10.5 9.16667 10.5H1.83333C1.46667 10.5 1.22222 10.25 1.22222 9.875V9.25H9.77778V9.875Z",
                fill: "white",
                fillOpacity: "0.25",
              }),
            }),
            i.jsx("h2", {
              className: "text-white text-xs font-bold",
              children: "LÍDERES",
            }),
          ],
        }),
      }),
      i.jsx("div", {
        className: "w-full flex flex-col gap-2 overflow-y-auto",
        children: r.map((s) =>
          i.jsxs(
            "div",
            {
              className: "w-full flex items-center gap-3 flex-none",
              children: [
                i.jsxs("svg", {
                  width: "2.3125rem",
                  height: "2rem",
                  viewBox: "0 0 37 32",
                  fill: "none",
                  xmlns: "http://www.w3.org/2000/svg",
                  children: [
                    i.jsx("path", {
                      d: "M0 16L9.25 8.0429e-07L27.75 0L37 16L27.75 32L9.25 32L0 16Z",
                      fill: "#ff4848ff",
                    }),
                    i.jsx("path", {
                      d: "M12.6667 19.5L11 9.875L15.5833 14.25L18.5 9L21.4167 14.25L26 9.875L24.3333 19.5H12.6667ZM24.3333 22.125C24.3333 22.65 24 23 23.5 23H13.5C13 23 12.6667 22.65 12.6667 22.125V21.25H24.3333V22.125Z",
                      fill: "#171918",
                    }),
                  ],
                }),
                i.jsxs("div", {
                  className:
                    "flex-1 h-8 bg-[#ff4848ff]/[.08] rounded-[.3125rem] px-3 flex items-center justify-between",
                  children: [
                    i.jsx("p", {
                      className: "text-white text-xs font-bold uppercase",
                      children: s.name,
                    }),
                    i.jsx("p", {
                      className:
                        "text-[#151716] text-xs font-bold h-5 bg-[#ff4848ff] px-[.375rem] rounded flex items-center justify-center",
                      children: s.user_id,
                    }),
                  ],
                }),
              ],
            },
            s.user_id,
          ),
        ),
      }),
    ],
  });
}
function R5({ page: r }) {
  const s = p.useRef(null),
    [a, c] = p.useState(!1),
    d = () => {
      var x;
      const m = (x = s.current) == null ? void 0 : x.value;
      se("ContractMember", { id: Number(m) }, !0).then((h) => {
        h && c(!1);
      });
    };
  return i.jsxs(jt, {
    open: a,
    onOpenChange: c,
    children: [
      i.jsx(Nt, {
        asChild: !0,
        children:
          r === "home"
            ? i.jsx("button", {
                className:
                  "w-full h-8 border-[.0625rem] border-[#ff4848ff] rounded-[.3125rem] text-[#ff4848ff] text-sm font-bold",
                children: "CONVIDAR",
              })
            : i.jsxs("button", {
                className:
                  "w-[10rem] h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] flex items-center justify-center gap-2 text-[#151716] text-sm font-bold",
                children: [
                  i.jsx("svg", {
                    width: ".8125rem",
                    height: ".625rem",
                    viewBox: "0 0 13 10",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      "fill-rule": "evenodd",
                      "clip-rule": "evenodd",
                      d: "M0.761522 0.732233C0 1.46447 0 2.64298 0 5C0 7.35702 0 8.53553 0.761522 9.26777C1.52304 10 2.7487 10 5.2 10H7.8C10.2513 10 11.477 10 12.2385 9.26777C13 8.53553 13 7.35702 13 5C13 2.64298 13 1.46447 12.2385 0.732233C11.477 0 10.2513 0 7.8 0H5.2C2.7487 0 1.52304 0 0.761522 0.732233ZM10.7745 2.19991C10.9469 2.39879 10.9189 2.69437 10.7121 2.8601L9.28438 4.0041C8.70824 4.46577 8.24128 4.83995 7.82913 5.09483C7.39981 5.36033 6.9817 5.52805 6.5 5.52805C6.0183 5.52805 5.60019 5.36033 5.17087 5.09483C4.75873 4.83995 4.29176 4.46577 3.71563 4.00411L2.28791 2.8601C2.08107 2.69437 2.05313 2.39879 2.22549 2.19991C2.39785 2.00103 2.70525 1.97416 2.91209 2.1399L4.31537 3.26432C4.9218 3.75024 5.34282 4.08651 5.69828 4.30633C6.04236 4.51912 6.2757 4.59055 6.5 4.59055C6.7243 4.59055 6.95764 4.51912 7.30172 4.30633C7.65718 4.08651 8.0782 3.75024 8.68463 3.26432L10.0879 2.1399C10.2947 1.97416 10.6021 2.00103 10.7745 2.19991Z",
                      fill: "#151716",
                    }),
                  }),
                  "CONTRATAR",
                ],
              }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22rem] p-4 rounded-[.5625rem] flex flex-col gap-4 border-[.0563rem] border-white/10 bg-[#151716]",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2",
                children: [
                  i.jsx("svg", {
                    width: ".8125rem",
                    height: ".625rem",
                    viewBox: "0 0 13 10",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      "fill-rule": "evenodd",
                      "clip-rule": "evenodd",
                      d: "M0.761522 0.732233C0 1.46447 0 2.64298 0 5C0 7.35702 0 8.53553 0.761522 9.26777C1.52304 10 2.7487 10 5.2 10H7.8C10.2513 10 11.477 10 12.2385 9.26777C13 8.53553 13 7.35702 13 5C13 2.64298 13 1.46447 12.2385 0.732233C11.477 0 10.2513 0 7.8 0H5.2C2.7487 0 1.52304 0 0.761522 0.732233ZM10.7745 2.19991C10.9469 2.39879 10.9189 2.69437 10.7121 2.8601L9.28438 4.0041C8.70824 4.46577 8.24128 4.83995 7.82913 5.09483C7.39981 5.36033 6.9817 5.52805 6.5 5.52805C6.0183 5.52805 5.60019 5.36033 5.17087 5.09483C4.75873 4.83995 4.29176 4.46577 3.71563 4.00411L2.28791 2.8601C2.08107 2.69437 2.05313 2.39879 2.22549 2.19991C2.39785 2.00103 2.70525 1.97416 2.91209 2.1399L4.31537 3.26432C4.9218 3.75024 5.34282 4.08651 5.69828 4.30633C6.04236 4.51912 6.2757 4.59055 6.5 4.59055C6.7243 4.59055 6.95764 4.51912 7.30172 4.30633C7.65718 4.08651 8.0782 3.75024 8.68463 3.26432L10.0879 2.1399C10.2947 1.97416 10.6021 2.00103 10.7745 2.19991Z",
                      fill: "white",
                      "fill-opacity": "0.25",
                    }),
                  }),
                  i.jsx(Ll, {
                    className: "text-white/65 text-sm font-bold",
                    children: "CONTRATAR",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "ID DO JOGADOR",
                  }),
                  i.jsx("input", {
                    type: "number",
                    ref: s,
                    placeholder: "DIGITE O ID DO JOGADOR",
                    className:
                      "w-full h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 text-white/35 text-xs font-medium rounded-[.3125rem] placeholder:text-white/35",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx("button", {
                    onClick: d,
                    className:
                      "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                    children: "CONFIRMAR",
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function S9({ discord: r }) {
  function s() {
    window.invokeNative("openUrl", r);
  }
  return i.jsxs("div", {
    className:
      "w-[16.5rem] h-[10.6875rem] border-[.0625rem] border-[#ff4848ff] rounded-[.3125rem] py-5 px-4 flex flex-col items-center justify-between",
    children: [
      i.jsxs("div", {
        className: "w-full flex flex-col items-center gap-3",
        children: [
          i.jsx("p", {
            className:
              "text-[#ff4848ff] text-[.8125rem] font-medium leading-none",
            children: "CONVIDE PARA SUA FAC",
          }),
          i.jsx(R5, { page: "home" }),
        ],
      }),
      i.jsxs("div", {
        className: "w-full flex flex-col items-center gap-3",
        children: [
          i.jsx("p", {
            className:
              "text-[#ff4848ff] text-[.8125rem] font-medium leading-none",
            children: "DISCORD DO GRUPO",
          }),
          i.jsxs("button", {
            onClick: s,
            className:
              "w-full h-8 border-[.0625rem] border-white/35 rounded-[.3125rem] bg-[#ff4848ff] text-[#151716] text-sm font-bold flex items-center justify-center gap-2",
            children: [
              i.jsx("svg", {
                width: ".9375rem",
                height: ".75rem",
                viewBox: "0 0 15 12",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                children: i.jsx("path", {
                  d: "M12.6919 0.997242C11.7419 0.532362 10.7133 0.19495 9.64181 0C9.62297 0.000281706 9.605 0.00836692 9.59181 0.0224943C9.46323 0.26993 9.31323 0.592347 9.21323 0.839782C8.07676 0.659942 6.92103 0.659942 5.78456 0.839782C5.68456 0.584848 5.53455 0.26993 5.39884 0.0224943C5.39169 0.00749822 5.37026 0 5.34883 0C4.27738 0.19495 3.25592 0.532362 2.29875 0.997242C2.29161 0.997242 2.28447 1.00474 2.27732 1.01224C0.334412 4.06395 -0.201317 7.03318 0.0629761 9.97242C0.0629761 9.98741 0.0701191 10.0024 0.0844052 10.0099C1.37015 10.9997 2.6059 11.5995 3.82737 11.9969C3.84879 12.0044 3.87022 11.9969 3.87737 11.9819C4.16309 11.5695 4.42024 11.1346 4.64167 10.6772C4.65596 10.6472 4.64167 10.6173 4.6131 10.6098C4.20595 10.4448 3.82022 10.2498 3.44164 10.0249C3.41307 10.0099 3.41307 9.96492 3.4345 9.94243C3.51307 9.88244 3.59164 9.81496 3.67022 9.75497C3.6845 9.73998 3.70593 9.73998 3.72022 9.74748C6.17743 10.9247 8.8275 10.9247 11.2561 9.74748C11.2704 9.73998 11.2919 9.73998 11.3061 9.75497C11.3847 9.82246 11.4633 9.88244 11.5419 9.94992C11.5704 9.97242 11.5704 10.0174 11.5347 10.0324C11.1633 10.2648 10.7704 10.4523 10.3633 10.6173C10.3347 10.6247 10.3275 10.6622 10.3347 10.6847C10.5633 11.1421 10.8204 11.577 11.099 11.9894C11.1204 11.9969 11.1419 12.0044 11.1633 11.9969C12.3919 11.5995 13.6276 10.9997 14.9134 10.0099C14.9277 10.0024 14.9348 9.98741 14.9348 9.97242C15.2491 6.5758 14.4134 3.62906 12.7205 1.01224C12.7133 1.00474 12.7062 0.997242 12.6919 0.997242ZM5.01311 8.18038C4.27738 8.18038 3.66307 7.46807 3.66307 6.59079C3.66307 5.71352 4.26309 5.0012 5.01311 5.0012C5.77028 5.0012 6.37029 5.72102 6.36315 6.59079C6.36315 7.46807 5.76313 8.18038 5.01311 8.18038ZM9.99182 8.18038C9.25609 8.18038 8.64178 7.46807 8.64178 6.59079C8.64178 5.71352 9.2418 5.0012 9.99182 5.0012C10.749 5.0012 11.349 5.72102 11.3419 6.59079C11.3419 7.46807 10.749 8.18038 9.99182 8.18038Z",
                  fill: "#151716",
                }),
              }),
              "DISCORD",
            ],
          }),
        ],
      }),
    ],
  });
}
const k9 = "" + new URL("radio-Dd-KcR8G.png", import.meta.url).href,
  R9 = "" + new URL("clothes-B9dCHD4u.png", import.meta.url).href,
  M9 = "" + new URL("location-mTBfnscv.png", import.meta.url).href,
  b9 = "" + new URL("vip-CYTKhejy.png", import.meta.url).href;
function P9({ onConnectRadio: r, onSetLocation: s, onSetCostume: a }) {
  const { factionVip: c } = Ze();
  return i.jsxs("div", {
    className: "w-full flex-1 flex items-center gap-3",
    children: [
      i.jsxs("div", {
        className:
          "flex-1 h-full bg-white/[.01] rounded-[.3125rem] border-[.0625rem] border-white/5 flex flex-col items-center justify-between p-4",
        children: [
          i.jsx("img", {
            src: k9,
            className: "size-[7.625rem] object-contain",
          }),
          i.jsx("p", {
            className: "text-white text-xs font-bold",
            children: "RÁDIO",
          }),
          i.jsx("button", {
            onClick: r,
            className:
              "text-[#151716] text-sm font-bold w-full h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem]",
            children: "ENTRAR",
          }),
        ],
      }),
      i.jsxs("div", {
        className:
          "flex-1 h-full bg-white/[.01] rounded-[.3125rem] border-[.0625rem] border-white/5 flex flex-col items-center justify-between p-4",
        children: [
          i.jsx("img", {
            src: M9,
            className: "size-[7.625rem] object-contain",
          }),
          i.jsx("p", {
            className: "text-white text-xs font-bold",
            children: "LOCALIZAÇÃO",
          }),
          i.jsx("button", {
            onClick: s,
            className:
              "text-[#151716] text-sm font-bold w-full h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem]",
            children: "MARCAR",
          }),
        ],
      }),
      i.jsxs("div", {
        className:
          "flex-1 h-full bg-white/[.01] rounded-[.3125rem] border-[.0625rem] border-white/5 flex flex-col items-center justify-between p-4",
        children: [
          i.jsx("img", {
            src: R9,
            className: "size-[7.625rem] object-contain",
          }),
          i.jsx("p", {
            className: "text-white text-xs font-bold",
            children: "VESTIMENTAS",
          }),
          i.jsx("button", {
            onClick: a,
            className:
              "text-[#151716] text-sm font-bold w-full h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem]",
            children: "VESTIR",
          }),
        ],
      }),
      i.jsxs("div", {
        className:
          "flex-1 h-full bg-white/[.01] rounded-[.3125rem] border-[.0625rem] border-white/5 flex flex-col items-center justify-between p-4",
        children: [
          i.jsx("img", {
            src: b9,
            className: "size-[7.625rem] object-contain",
          }),
          i.jsx("p", {
            className: "text-white/35 text-xs font-bold",
            children: "VIP FACÇÃO",
          }),
          i.jsx("div", {
            className:
              "text-white text-sm font-bold w-full h-8 bg-[#666666] rounded-[.3125rem] flex items-center justify-center",
            children: c || "SEM VIP",
          }),
        ],
      }),
    ],
  });
}
function O9() {
  const r = p.useRef(null),
    [s, a] = p.useState(!1);
  function c() {
    var m;
    const d = (m = r.current) == null ? void 0 : m.value;
    se("NewWarn", { message: String(d) }, !0).then((x) => {
      x && (a(!1), r.current && (r.current.value = ""));
    });
  }
  return i.jsxs(jt, {
    open: s,
    onOpenChange: a,
    children: [
      i.jsx(Nt, {
        asChild: !0,
        children: i.jsxs("button", {
          className:
            "flex items-center justify-center gap-2 px-2 h-5 border-[.0625rem] border-white/15 rounded-[.3125rem] text-white/50 text-xs font-semibold hover:border-[#ff4848ff] hover:text-[#ff4848ff] transition-colors",
          children: [
            i.jsx("svg", {
              width: ".5rem",
              height: ".5rem",
              viewBox: "0 0 8 8",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: i.jsx("path", {
                d: "M8 4.57143H4.57143V8H3.42857V4.57143H0V3.42857H3.42857V0H4.57143V3.42857H8V4.57143Z",
                fill: "currentColor",
              }),
            }),
            "NOVO",
          ],
        }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22rem] p-4 rounded-[.5625rem] flex flex-col gap-4 border-[.0563rem] border-white/10 bg-[#151716]",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2",
                children: [
                  i.jsx("svg", {
                    width: ".75rem",
                    height: ".75rem",
                    viewBox: "0 0 12 12",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      d: "M6 0C2.68629 0 0 2.68629 0 6C0 9.31371 2.68629 12 6 12C9.31371 12 12 9.31371 12 6C12 2.68629 9.31371 0 6 0ZM6 2.57143C6.31543 2.57143 6.57143 2.82743 6.57143 3.14286V6C6.57143 6.31543 6.31543 6.57143 6 6.57143C5.68457 6.57143 5.42857 6.31543 5.42857 6V3.14286C5.42857 2.82743 5.68457 2.57143 6 2.57143ZM6 9.42857C5.52686 9.42857 5.14286 9.04457 5.14286 8.57143C5.14286 8.09829 5.52686 7.71429 6 7.71429C6.47314 7.71429 6.85714 8.09829 6.85714 8.57143C6.85714 9.04457 6.47314 9.42857 6 9.42857Z",
                      fill: "white",
                      fillOpacity: "0.25",
                    }),
                  }),
                  i.jsx(Ll, {
                    className: "text-white/65 text-sm font-bold",
                    children: "CRIAR AVISO",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "DESCRIÇÃO",
                  }),
                  i.jsx("textarea", {
                    ref: r,
                    placeholder: "DIGITE A DESCRIÇÃO DO AVISO",
                    maxLength: 700,
                    className:
                      "w-full h-[8rem] bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 py-3 text-white text-xs font-medium rounded-[.3125rem] placeholder:text-white/35 resize-none focus:outline-none",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx("button", {
                    onClick: c,
                    className:
                      "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                    children: "CONFIRMAR",
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function _9({ warnings: r, isLeader: s, onDeleteWarning: a }) {
  return i.jsxs("div", {
    className:
      "flex-1 h-full p-4 bg-white/[.01] border-[.0625rem] border-white/5 rounded-[.3125rem] flex flex-col gap-3",
    children: [
      i.jsxs("div", {
        className: "w-full flex items-center justify-between",
        children: [
          i.jsxs("div", {
            className: "flex items-center gap-2",
            children: [
              i.jsx("svg", {
                width: ".75rem",
                height: ".75rem",
                viewBox: "0 0 12 12",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                children: i.jsx("path", {
                  fillRule: "evenodd",
                  clipRule: "evenodd",
                  d: "M0.372687 0.852C0.609367 0.62553 0.928718 0.5 1.2594 0.5H10.7406C11.0713 0.5 11.3906 0.62553 11.6273 0.852C11.864 1.07847 12 1.38841 12 1.71324V7.69853C12 8.02335 11.8647 8.33329 11.6273 8.55976C11.3906 8.78623 11.0713 8.91177 10.7406 8.91177H8.3338L6.5337 11.2412C6.47159 11.3215 6.39107 11.3868 6.29849 11.4317C6.20592 11.4766 6.10384 11.5 6.00033 11.5C5.89683 11.5 5.79475 11.4766 5.70217 11.4317C5.6096 11.3868 5.52907 11.3215 5.46697 11.2412L3.66687 8.91177H1.2594C0.928718 8.91177 0.609367 8.78623 0.372687 8.55976C0.254864 8.44734 0.161241 8.31331 0.0972605 8.16546C0.0332804 8.01761 0.000219605 7.85889 0 7.69853V1.71324C0 1.38841 0.135341 1.07847 0.372687 0.852ZM3.0375 2.76471C2.86068 2.76471 2.6911 2.83288 2.56607 2.95423C2.44104 3.07557 2.3708 3.24015 2.3708 3.41176C2.3708 3.58338 2.44104 3.74796 2.56607 3.8693C2.6911 3.99065 2.86068 4.05882 3.0375 4.05882H8.37113C8.54795 4.05882 8.71753 3.99065 8.84256 3.8693C8.96759 3.74796 9.03784 3.58338 9.03784 3.41176C9.03784 3.24015 8.96759 3.07557 8.84256 2.95423C8.71753 2.83288 8.54795 2.76471 8.37113 2.76471H3.0375ZM3.0375 5.02941C2.86068 5.02941 2.6911 5.09758 2.56607 5.21893C2.44104 5.34028 2.3708 5.50486 2.3708 5.67647C2.3708 5.84808 2.44104 6.01266 2.56607 6.13401C2.6911 6.25536 2.86068 6.32353 3.0375 6.32353H6.00033C6.17715 6.32353 6.34673 6.25536 6.47176 6.13401C6.5968 6.01266 6.66704 5.84808 6.66704 5.67647C6.66704 5.50486 6.5968 5.34028 6.47176 5.21893C6.34673 5.09758 6.17715 5.02941 6.00033 5.02941H3.0375Z",
                  fill: "white",
                  fillOpacity: "0.25",
                }),
              }),
              i.jsx("h2", {
                className: "text-white text-xs font-bold",
                children: "AVISOS",
              }),
            ],
          }),
          s && i.jsx(O9, {}),
        ],
      }),
      i.jsx("div", {
        className: "w-full flex-1 flex flex-col gap-3 overflow-y-auto",
        children:
          r && r.length > 0
            ? r.map((c, d) =>
                i.jsxs(
                  "div",
                  {
                    className:
                      "w-full p-3 bg-white/[.02] rounded-md flex flex-col gap-2 flex-none",
                    children: [
                      i.jsxs("div", {
                        className: "w-full flex items-center justify-between",
                        children: [
                          i.jsxs("div", {
                            className: "flex items-center gap-3",
                            children: [
                              i.jsx("img", {
                                src: c.author_avatar,
                                alt: "",
                                className:
                                  "size-8 rounded-full border-[.0625rem] border-white/25 object-cover",
                              }),
                              i.jsx("div", {
                                className: "flex items-center gap-2",
                                children: i.jsx("p", {
                                  className: "text-white text-xs font-bold",
                                  children: c.author,
                                }),
                              }),
                            ],
                          }),
                          i.jsxs("div", {
                            className: "flex items-center gap-2",
                            children: [
                              i.jsx("p", {
                                className: "text-white/45 text-xs font-normal",
                                children: c.date,
                              }),
                              s &&
                                i.jsx("svg", {
                                  className:
                                    "size-4 flex-none cursor-pointer hover:opacity-70",
                                  onClick: () => a(d),
                                  width: "18",
                                  height: "18",
                                  viewBox: "0 0 18 18",
                                  fill: "none",
                                  xmlns: "http://www.w3.org/2000/svg",
                                  children: i.jsx("path", {
                                    d: "M15.75 3.375H3.375L4.5 16.875H13.5L14.625 3.375H2.25M9 6.75V13.5M11.8125 6.75L11.25 13.5M6.1875 6.75L6.75 13.5M6.75 3.375L7.3125 1.125H10.6875L11.25 3.375",
                                    stroke: "#CCCCCC",
                                    strokeOpacity: "0.6",
                                    strokeLinecap: "round",
                                    strokeLinejoin: "round",
                                  }),
                                }),
                            ],
                          }),
                        ],
                      }),
                      i.jsx("p", {
                        className: "text-white/45 text-xs font-normal",
                        children: c.message,
                      }),
                    ],
                  },
                  d,
                ),
              )
            : i.jsx("div", {
                className: "w-full h-full flex items-center justify-center",
                children: i.jsx("p", {
                  className: "text-white/30 text-sm",
                  children: "Nenhum aviso para exibir",
                }),
              }),
      }),
    ],
  });
}
function F9() {
  const {
      radio: r,
      preset: s,
      permissions: a,
      goals: c,
      warnings: d,
      user_id: m,
      name: x,
      discord: h,
      update: v,
    } = Ze(),
    [y, M] = p.useState({
      reward: 0,
      goalsCurrent: 0,
      goalsMax: 0,
      rewards: [],
    }),
    [j, b] = p.useState([]),
    [O, H] = p.useState({ status: [], rankingPosition: 1 });
  (p.useEffect(() => {
    (se("GetGoalsDetails", null, {
      reward: 2e4,
      rewards: [
        { image: "", amount: 300, max: 10 },
        { image: "", amount: 300, max: 50 },
      ],
      goalsCurrent: 0,
      goalsMax: 350,
    }).then(M),
      se("getLeaders", null, [{ name: "Igor", user_id: 1 }]).then(b));
  }, []),
    p.useEffect(() => {
      se("getPersonalRanking", m, {
        status: [1, 2, 3, 3, 1, 1, 1],
        rankingPosition: 1,
      }).then(H);
    }, []));
  function N() {
    se("ConnectRadio", { radio: r }, !0);
  }
  function k() {
    se("SetCostume", { preset: s }, !0);
  }
  function P() {
    se("SetLocation", null, !0);
  }
  function T(ee) {
    se("ClaimRewards", {
      rewards: y.rewards.map((K) => ({ ...K, amount: Math.min(ee, K.max) })),
    }).then(() => {});
  }
  function V(ee) {
    const K = ee.replace(/\D/g, "");
    (c && ((c.prize = K), v({ goals: c })),
      se(
        "EditMyGoal",
        { payment: K, items: (c == null ? void 0 : c.my) || [] },
        c,
      ).then(() => {}));
  }
  function Z(ee) {
    se("DeleteWarning", { index: ee });
  }
  return i.jsxs("div", {
    className: "size-full flex items-center gap-3",
    children: [
      i.jsxs("div", {
        className: "w-[54.75rem] h-full flex flex-col gap-3",
        children: [
          i.jsxs("div", {
            className: "w-full flex items-center gap-3",
            children: [
              i.jsx(N9, {
                rankingPosition: (O == null ? void 0 : O.rankingPosition) || 1,
                status: (O == null ? void 0 : O.status) || [],
                name: x,
              }),
              i.jsx(L9, {
                goalsDetails: y,
                isLeader: (a == null ? void 0 : a.leader) || !1,
                onClaimRewards: T,
                onSubmitReward: V,
              }),
            ],
          }),
          i.jsxs("div", {
            className: "w-full flex items-center gap-3",
            children: [i.jsx(E9, { leaders: j }), i.jsx(S9, { discord: h })],
          }),
          i.jsx(P9, { onConnectRadio: N, onSetLocation: P, onSetCostume: k }),
        ],
      }),
      i.jsx(_9, {
        warnings: d,
        isLeader: (a == null ? void 0 : a.leader) || !1,
        onDeleteWarning: Z,
      }),
    ],
  });
}
function I9() {
  const r = p.useRef(null);
  function s() {
    var a;
    se("NewWarn", {
      message: String((a = r.current) == null ? void 0 : a.value),
    });
  }
  return i.jsxs(jt, {
    children: [
      i.jsx(Nt, {
        asChild: !0,
        children: i.jsxs("button", {
          className:
            "flex items-center justify-center gap-2 px-2 h-5 border-[.0625rem] border-white/15 rounded-[.3125rem] text-white/50 text-xs font-semibold hover:border-[#ff4848ff] hover:text-[#ff4848ff] transition-colors",
          children: [
            i.jsx("svg", {
              width: ".5rem",
              height: ".5rem",
              viewBox: "0 0 8 8",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: i.jsx("path", {
                d: "M8 4.57143H4.57143V8H3.42857V4.57143H0V3.42857H3.42857V0H4.57143V3.42857H8V4.57143Z",
                fill: "currentColor",
              }),
            }),
            "NOVO",
          ],
        }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[25rem] px-[1.5625rem] pt-[2.1875rem] pb-[1.5625rem] rounded-xl flex flex-col gap-4 border-[.0563rem] border-white/30 bg-[#101010]/90",
            children: [
              i.jsxs("svg", {
                className: "-mt-[4rem] mx-auto",
                width: "58",
                height: "58",
                viewBox: "0 0 58 58",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                children: [
                  i.jsx("path", {
                    d: "M4.33013 34.5C2.36517 31.0966 2.36517 26.9034 4.33013 23.5L11.9019 10.3853C13.8669 6.98186 17.4983 4.88527 21.4282 4.88527L36.5718 4.88527C40.5017 4.88527 44.1331 6.98186 46.0981 10.3853L53.6699 23.5C55.6348 26.9034 55.6348 31.0966 53.6699 34.5L46.0981 47.6147C44.1331 51.0181 40.5017 53.1147 36.5718 53.1147L21.4282 53.1147C17.4983 53.1147 13.8669 51.0181 11.9019 47.6147L4.33013 34.5Z",
                    fill: "url(#paint0_radial_182_3593)",
                    fillOpacity: "0.45",
                    stroke: "#ff4848ff",
                    strokeWidth: "2",
                  }),
                  i.jsx("path", {
                    d: "M8.88675 34C7.10042 30.906 7.10042 27.094 8.88675 24L14.6132 14.0814C16.3996 10.9874 19.7008 9.08142 23.2735 9.08142L34.7265 9.08142C38.2992 9.08142 41.6004 10.9874 43.3868 14.0814L49.1132 24C50.8996 27.094 50.8996 30.906 49.1132 34L43.3868 43.9186C41.6004 47.0126 38.2992 48.9186 34.7265 48.9186L23.2735 48.9186C19.7008 48.9186 16.3996 47.0126 14.6132 43.9186L8.88675 34Z",
                    fill: "#ff4848ff",
                  }),
                  i.jsx("path", {
                    d: "M38.9 35.1001L20.2 30.7001C19.5126 29.9467 19.1217 28.9696 19.1 27.95C19.1217 26.9305 19.5126 25.9534 20.2 25.2L38.9 20.8V35.1001Z",
                    fill: "#1E1E1E",
                  }),
                  i.jsx("path", {
                    d: "M26.8 29.6C26.8 28.385 25.8151 27.4 24.6 27.4C23.385 27.4 22.4 28.385 22.4 29.6V34C22.4 35.2151 23.385 36.2 24.6 36.2C25.8151 36.2 26.8 35.2151 26.8 34V29.6Z",
                    fill: "#1E1E1E",
                  }),
                  i.jsx("defs", {
                    children: i.jsxs("radialGradient", {
                      id: "paint0_radial_182_3593",
                      cx: "0",
                      cy: "0",
                      r: "1",
                      gradientUnits: "userSpaceOnUse",
                      gradientTransform:
                        "translate(29 -0.0828493) rotate(90) scale(64.4007 657.175)",
                      children: [
                        i.jsx("stop", {}),
                        i.jsx("stop", { offset: "1", stopOpacity: "0" }),
                      ],
                    }),
                  }),
                ],
              }),
              i.jsx(Ll, {
                className:
                  "text-white text-[1.125rem] leading-[.8125rem] font-extrabold text-center",
                children: "CRIAR AVISO",
              }),
              i.jsx(w9, {}),
              i.jsx("textarea", {
                ref: r,
                placeholder: "Insira uma descrição",
                maxLength: 700,
                className:
                  "w-full h-[10.5625rem] bg-white/[0.03] border-[.05rem] border-white/30 focus:outline-none p-[.9375rem] flex items-center justify-center rounded-[.6875rem] placeholder:text-white/40 text-white/90 text-[.8125rem] leading-[1rem] resize-none",
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    asChild: !0,
                    children: i.jsx("button", {
                      className:
                        "w-[10.6875rem] h-8 rounded-[.5625rem] flex items-center justify-center border border-[#DDDDDD]/20 bg-[#DDDDDD]/30",
                      children: i.jsx("span", {
                        className:
                          "text-white text-xs leading-[.5625rem] font-extrabold",
                        children: "RETORNAR",
                      }),
                    }),
                  }),
                  i.jsx(qe, {
                    asChild: !0,
                    onClick: s,
                    children: i.jsx("button", {
                      className:
                        "w-[10.6875rem] h-8 bg-[#ff4848ff] rounded-[.5625rem] flex items-center justify-center",
                      style: {
                        boxShadow:
                          "0px 0px 4px 0px rgba(0, 0, 0, 0.10), 0px 0px 14px 0px rgba(255, 188, 72, 0.45)",
                      },
                      children: i.jsx("span", {
                        className:
                          "text-[#1E1E1E] text-xs leading-[.5625rem] font-extrabold",
                        children: "CRIAR",
                      }),
                    }),
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function D9({ warnings: r, isLeader: s, onDeleteWarning: a }) {
  return i.jsxs("div", {
    className:
      "flex-1 h-full p-4 bg-white/[.01] border-[.0625rem] border-white/5 rounded-[.3125rem] flex flex-col gap-3",
    children: [
      i.jsxs("div", {
        className: "w-full flex items-center justify-between",
        children: [
          i.jsxs("div", {
            className: "flex items-center gap-2",
            children: [
              i.jsx("svg", {
                width: ".75rem",
                height: ".75rem",
                viewBox: "0 0 12 12",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                children: i.jsx("path", {
                  fillRule: "evenodd",
                  clipRule: "evenodd",
                  d: "M0.372687 0.852C0.609367 0.62553 0.928718 0.5 1.2594 0.5H10.7406C11.0713 0.5 11.3906 0.62553 11.6273 0.852C11.864 1.07847 12 1.38841 12 1.71324V7.69853C12 8.02335 11.8647 8.33329 11.6273 8.55976C11.3906 8.78623 11.0713 8.91177 10.7406 8.91177H8.3338L6.5337 11.2412C6.47159 11.3215 6.39107 11.3868 6.29849 11.4317C6.20592 11.4766 6.10384 11.5 6.00033 11.5C5.89683 11.5 5.79475 11.4766 5.70217 11.4317C5.6096 11.3868 5.52907 11.3215 5.46697 11.2412L3.66687 8.91177H1.2594C0.928718 8.91177 0.609367 8.78623 0.372687 8.55976C0.254864 8.44734 0.161241 8.31331 0.0972605 8.16546C0.0332804 8.01761 0.000219605 7.85889 0 7.69853V1.71324C0 1.38841 0.135341 1.07847 0.372687 0.852ZM3.0375 2.76471C2.86068 2.76471 2.6911 2.83288 2.56607 2.95423C2.44104 3.07557 2.3708 3.24015 2.3708 3.41176C2.3708 3.58338 2.44104 3.74796 2.56607 3.8693C2.6911 3.99065 2.86068 4.05882 3.0375 4.05882H8.37113C8.54795 4.05882 8.71753 3.99065 8.84256 3.8693C8.96759 3.74796 9.03784 3.58338 9.03784 3.41176C9.03784 3.24015 8.96759 3.07557 8.84256 2.95423C8.71753 2.83288 8.54795 2.76471 8.37113 2.76471H3.0375ZM3.0375 5.02941C2.86068 5.02941 2.6911 5.09758 2.56607 5.21893C2.44104 5.34028 2.3708 5.50486 2.3708 5.67647C2.3708 5.84808 2.44104 6.01266 2.56607 6.13401C2.6911 6.25536 2.86068 6.32353 3.0375 6.32353H6.00033C6.17715 6.32353 6.34673 6.25536 6.47176 6.13401C6.5968 6.01266 6.66704 5.84808 6.66704 5.67647C6.66704 5.50486 6.5968 5.34028 6.47176 5.21893C6.34673 5.09758 6.17715 5.02941 6.00033 5.02941H3.0375Z",
                  fill: "white",
                  fillOpacity: "0.25",
                }),
              }),
              i.jsx("h2", {
                className: "text-white text-xs font-bold",
                children: "AVISOS",
              }),
            ],
          }),
          s && i.jsx(I9, {}),
        ],
      }),
      i.jsx("div", {
        className: "w-full flex-1 flex flex-col gap-3 overflow-y-auto",
        children:
          r && r.length > 0
            ? r.map((c, d) =>
                i.jsxs(
                  "div",
                  {
                    className:
                      "w-full p-3 bg-white/[.02] rounded-md flex flex-col gap-2 flex-none",
                    children: [
                      i.jsxs("div", {
                        className: "w-full flex items-center justify-between",
                        children: [
                          i.jsxs("div", {
                            className: "flex items-center gap-3",
                            children: [
                              i.jsx("img", {
                                src: c.author_avatar,
                                alt: "",
                                className:
                                  "size-8 rounded-full border-[.0625rem] border-white/25 object-cover",
                              }),
                              i.jsx("div", {
                                className: "flex items-center gap-2",
                                children: i.jsx("p", {
                                  className: "text-white text-xs font-bold",
                                  children: c.author,
                                }),
                              }),
                            ],
                          }),
                          i.jsxs("div", {
                            className: "flex items-center gap-2",
                            children: [
                              i.jsx("p", {
                                className: "text-white/45 text-xs font-normal",
                                children: c.date,
                              }),
                              s &&
                                i.jsx("svg", {
                                  className:
                                    "size-4 flex-none cursor-pointer hover:opacity-70",
                                  onClick: () => a(d),
                                  width: "18",
                                  height: "18",
                                  viewBox: "0 0 18 18",
                                  fill: "none",
                                  xmlns: "http://www.w3.org/2000/svg",
                                  children: i.jsx("path", {
                                    d: "M15.75 3.375H3.375L4.5 16.875H13.5L14.625 3.375H2.25M9 6.75V13.5M11.8125 6.75L11.25 13.5M6.1875 6.75L6.75 13.5M6.75 3.375L7.3125 1.125H10.6875L11.25 3.375",
                                    stroke: "#CCCCCC",
                                    strokeOpacity: "0.6",
                                    strokeLinecap: "round",
                                    strokeLinejoin: "round",
                                  }),
                                }),
                            ],
                          }),
                        ],
                      }),
                      i.jsx("p", {
                        className: "text-white/45 text-xs font-normal",
                        children: c.message,
                      }),
                    ],
                  },
                  d,
                ),
              )
            : i.jsx("div", {
                className: "w-full h-full flex items-center justify-center",
                children: i.jsx("p", {
                  className: "text-white/30 text-sm",
                  children: "Nenhum aviso para exibir",
                }),
              }),
      }),
    ],
  });
}
function T9({
  membersCount: r,
  onlineCount: s,
  search: a,
  onSearchChange: c,
  canInvite: d,
}) {
  return i.jsxs("div", {
    className: "w-full flex items-center justify-between",
    children: [
      i.jsxs("div", {
        className: "flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".625rem",
            height: ".625rem",
            viewBox: "0 0 10 10",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M9.92272 9.38424C9.96571 9.44137 9.99192 9.50935 9.99841 9.58055C10.0049 9.65176 9.99141 9.72336 9.95945 9.78732C9.92749 9.85128 9.87833 9.90506 9.81749 9.94263C9.75665 9.9802 9.68654 10.0001 9.61504 10H0.384602C0.313177 10 0.243162 9.98011 0.182405 9.94257C0.121647 9.90502 0.0725459 9.8513 0.0406036 9.78743C0.00866132 9.72355 -0.00486013 9.65204 0.00155424 9.58091C0.00796861 9.50979 0.0340654 9.44185 0.0769205 9.38472C0.417478 8.92819 0.871614 8.56874 1.39418 8.3421C1.10774 8.0807 0.907032 7.73882 0.818408 7.36132C0.729783 6.98382 0.757381 6.58835 0.897579 6.22682C1.03778 5.86529 1.28402 5.55459 1.604 5.3355C1.92397 5.11641 2.30272 4.99917 2.69053 4.99917C3.07834 4.99917 3.45708 5.11641 3.77706 5.3355C4.09703 5.55459 4.34328 5.86529 4.48348 6.22682C4.62367 6.58835 4.65127 6.98382 4.56265 7.36132C4.47402 7.73882 4.27332 8.0807 3.98688 8.3421C4.36389 8.50504 4.7065 8.73815 4.99645 9.02901C5.28641 8.73815 5.62902 8.50504 6.00603 8.3421C5.71959 8.0807 5.51888 7.73882 5.43026 7.36132C5.34164 6.98382 5.36923 6.58835 5.50943 6.22682C5.64963 5.86529 5.89588 5.55459 6.21585 5.3355C6.53582 5.11641 6.91457 4.99917 7.30238 4.99917C7.69019 4.99917 8.06894 5.11641 8.38891 5.3355C8.70889 5.55459 8.95513 5.86529 9.09533 6.22682C9.23553 6.58835 9.26313 6.98382 9.1745 7.36132C9.08588 7.73882 8.88517 8.0807 8.59873 8.3421C9.12372 8.56754 9.58029 8.92691 9.92272 9.38424ZM0.153841 4.92392C0.194246 4.95422 0.240225 4.97627 0.289151 4.9888C0.338077 5.00134 0.388994 5.00411 0.438993 4.99697C0.488991 4.98983 0.537094 4.97291 0.580554 4.94718C0.624013 4.92145 0.661979 4.88741 0.692283 4.84701C0.925142 4.53657 1.22709 4.28461 1.57422 4.11107C1.92134 3.93753 2.30411 3.84718 2.69221 3.84718C3.08031 3.84718 3.46308 3.93753 3.8102 4.11107C4.15733 4.28461 4.45928 4.53657 4.69214 4.84701C4.72796 4.89477 4.77442 4.93354 4.82782 4.96024C4.88122 4.98693 4.94011 5.00083 4.99982 5.00083C5.05953 5.00083 5.11841 4.98693 5.17182 4.96024C5.22522 4.93354 5.27168 4.89477 5.3075 4.84701C5.54036 4.53657 5.84231 4.28461 6.18943 4.11107C6.53656 3.93753 6.91933 3.84718 7.30743 3.84718C7.69553 3.84718 8.0783 3.93753 8.42542 4.11107C8.77255 4.28461 9.0745 4.53657 9.30736 4.84701C9.33769 4.88741 9.37569 4.92144 9.41918 4.94716C9.46267 4.97288 9.51079 4.98978 9.56082 4.9969C9.61084 5.00402 9.66177 5.00122 9.71071 4.98865C9.75965 4.97609 9.80563 4.95401 9.84604 4.92368C9.88644 4.89335 9.92048 4.85536 9.9462 4.81188C9.97192 4.76839 9.98882 4.72027 9.99594 4.67026C10.0031 4.62024 10.0003 4.56931 9.9877 4.52038C9.97513 4.47145 9.95305 4.42547 9.92272 4.38507C9.58215 3.92867 9.128 3.56938 8.60546 3.34294C8.8919 3.08154 9.09261 2.73965 9.18123 2.36216C9.26986 1.98466 9.24226 1.58919 9.10206 1.22766C8.96186 0.866122 8.71562 0.555419 8.39564 0.336329C8.07567 0.117239 7.69692 0 7.30911 0C6.9213 0 6.54255 0.117239 6.22258 0.336329C5.90261 0.555419 5.65636 0.866122 5.51616 1.22766C5.37596 1.58919 5.34837 1.98466 5.43699 2.36216C5.52562 2.73965 5.72632 3.08154 6.01276 3.34294C5.63575 3.50588 5.29314 3.73898 5.00318 4.02984C4.71323 3.73898 4.37062 3.50588 3.99361 3.34294C4.28005 3.08154 4.48075 2.73965 4.56938 2.36216C4.658 1.98466 4.63041 1.58919 4.49021 1.22766C4.35001 0.866122 4.10376 0.555419 3.78379 0.336329C3.46382 0.117239 3.08507 0 2.69726 0C2.30945 0 1.9307 0.117239 1.61073 0.336329C1.29075 0.555419 1.04451 0.866122 0.904309 1.22766C0.764111 1.58919 0.736513 1.98466 0.825138 2.36216C0.913763 2.73965 1.11447 3.08154 1.40091 3.34294C0.875893 3.56857 0.419337 3.9281 0.0769205 4.38555C0.0466165 4.42595 0.0245677 4.47192 0.0120329 4.52084C-0.000501866 4.56976 -0.00327709 4.62067 0.00386562 4.67067C0.0110083 4.72066 0.0279292 4.76875 0.0536619 4.81221C0.0793947 4.85566 0.113436 4.89362 0.153841 4.92392Z",
              fill: "white",
              "fill-opacity": "0.25",
            }),
          }),
          i.jsx("h2", {
            className: "text-white text-xs font-bold",
            children: "LISTA DE MEMBROS",
          }),
          i.jsxs("p", {
            className:
              "text-white/50 text-xs font-normal h-[1.375rem] flex items-center justify-center bg-white/5 border-[.0625rem] border-white/[.03] px-2 rounded-[.3125rem]",
            children: [s, "/", r],
          }),
        ],
      }),
      i.jsxs("div", {
        className: "flex items-center gap-3",
        children: [
          i.jsxs("div", {
            className:
              "flex items-center gap-2 w-[15rem] h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4",
            children: [
              i.jsx("svg", {
                className: "flex-none",
                width: ".75rem",
                height: ".75rem",
                viewBox: "0 0 12 12",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                children: i.jsx("path", {
                  d: "M9.46992 8.63464L12 11.1641L11.1641 12L8.63464 9.46992C7.69346 10.2244 6.52279 10.6348 5.31653 10.6331C2.38181 10.6331 0 8.25126 0 5.31653C0 2.38181 2.38181 0 5.31653 0C8.25126 0 10.6331 2.38181 10.6331 5.31653C10.6348 6.52279 10.2244 7.69346 9.46992 8.63464ZM8.28493 8.19632C9.03446 7.42525 9.45312 6.39187 9.45161 5.31653C9.45161 3.03219 7.60087 1.18145 5.31653 1.18145C3.03219 1.18145 1.18145 3.03219 1.18145 5.31653C1.18145 7.60087 3.03219 9.45161 5.31653 9.45161C6.39187 9.45312 7.42525 9.03446 8.19632 8.28493L8.28493 8.19632Z",
                  fill: "white",
                  "fill-opacity": "0.25",
                }),
              }),
              i.jsx("input", {
                type: "text",
                value: a,
                onChange: (m) => c(m.target.value),
                placeholder: "PESQUISAR...",
                className:
                  "flex-1 h-full bg-transparent text-white text-xs font-medium placeholder:text-white/35",
              }),
            ],
          }),
          d && i.jsx(R5, {}),
        ],
      }),
    ],
  });
}
function A9({ sortStyle: r, sortOrder: s, onToggleSort: a }) {
  return i.jsxs("div", {
    className:
      "w-full h-8 bg-white/[.02] rounded-[.3125rem] flex items-center px-4",
    children: [
      i.jsxs("button", {
        onClick: () => a("id"),
        className: "flex items-center gap-1.5 w-[8rem] cursor-pointer",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold",
              r === "id" ? "text-white" : "text-white/60",
            ),
            children: "ID",
          }),
          i.jsx("svg", {
            width: ".5625rem",
            height: ".3125rem",
            viewBox: "0 0 9 5",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            className: ne(r === "id" && s === "desc" && "rotate-180"),
            children: i.jsx("path", {
              "fill-rule": "evenodd",
              "clip-rule": "evenodd",
              d: "M4.9788 4.8085C4.8518 4.93112 4.67958 5 4.5 5C4.32042 5 4.1482 4.93112 4.0212 4.8085L0.190107 1.10845C0.0667439 0.985094 -0.0015173 0.819876 2.57492e-05 0.648382C0.00156879 0.476888 0.072793 0.31284 0.198358 0.191571C0.323921 0.0703025 0.493779 0.00151491 0.671347 2.47955e-05C0.848914 -0.00146532 1.01998 0.0644608 1.14771 0.183604L4.5 3.42123L7.85229 0.183604C7.98002 0.0644608 8.15109 -0.00146532 8.32865 2.47955e-05C8.50622 0.00151491 8.67608 0.0703025 8.80164 0.191571C8.92721 0.31284 8.99843 0.476888 8.99997 0.648382C9.00152 0.819876 8.93326 0.985094 8.80989 1.10845L4.9788 4.8085Z",
              fill: "white",
              "fill-opacity": "0.25",
            }),
          }),
        ],
      }),
      i.jsxs("button", {
        onClick: () => a("name"),
        className: "flex items-center gap-1.5 w-[10.9167rem] cursor-pointer",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold",
              r === "name" ? "text-white" : "text-white/60",
            ),
            children: "NOME",
          }),
          i.jsx("svg", {
            width: ".5625rem",
            height: ".3125rem",
            viewBox: "0 0 9 5",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            className: ne(r === "name" && s === "desc" && "rotate-180"),
            children: i.jsx("path", {
              "fill-rule": "evenodd",
              "clip-rule": "evenodd",
              d: "M4.9788 4.8085C4.8518 4.93112 4.67958 5 4.5 5C4.32042 5 4.1482 4.93112 4.0212 4.8085L0.190107 1.10845C0.0667439 0.985094 -0.0015173 0.819876 2.57492e-05 0.648382C0.00156879 0.476888 0.072793 0.31284 0.198358 0.191571C0.323921 0.0703025 0.493779 0.00151491 0.671347 2.47955e-05C0.848914 -0.00146532 1.01998 0.0644608 1.14771 0.183604L4.5 3.42123L7.85229 0.183604C7.98002 0.0644608 8.15109 -0.00146532 8.32865 2.47955e-05C8.50622 0.00151491 8.67608 0.0703025 8.80164 0.191571C8.92721 0.31284 8.99843 0.476888 8.99997 0.648382C9.00152 0.819876 8.93326 0.985094 8.80989 1.10845L4.9788 4.8085Z",
              fill: "white",
              "fill-opacity": "0.25",
            }),
          }),
        ],
      }),
      i.jsxs("button", {
        onClick: () => a("role"),
        className: "flex items-center gap-1.5 w-[10.9167rem] cursor-pointer",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold",
              r === "role" ? "text-white" : "text-white/60",
            ),
            children: "CARGO",
          }),
          i.jsx("svg", {
            width: ".5625rem",
            height: ".3125rem",
            viewBox: "0 0 9 5",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            className: ne(r === "role" && s === "desc" && "rotate-180"),
            children: i.jsx("path", {
              "fill-rule": "evenodd",
              "clip-rule": "evenodd",
              d: "M4.9788 4.8085C4.8518 4.93112 4.67958 5 4.5 5C4.32042 5 4.1482 4.93112 4.0212 4.8085L0.190107 1.10845C0.0667439 0.985094 -0.0015173 0.819876 2.57492e-05 0.648382C0.00156879 0.476888 0.072793 0.31284 0.198358 0.191571C0.323921 0.0703025 0.493779 0.00151491 0.671347 2.47955e-05C0.848914 -0.00146532 1.01998 0.0644608 1.14771 0.183604L4.5 3.42123L7.85229 0.183604C7.98002 0.0644608 8.15109 -0.00146532 8.32865 2.47955e-05C8.50622 0.00151491 8.67608 0.0703025 8.80164 0.191571C8.92721 0.31284 8.99843 0.476888 8.99997 0.648382C9.00152 0.819876 8.93326 0.985094 8.80989 1.10845L4.9788 4.8085Z",
              fill: "white",
              "fill-opacity": "0.25",
            }),
          }),
        ],
      }),
      i.jsxs("button", {
        onClick: () => a("lastLogin"),
        className:
          "flex items-center justify-center gap-1.5 w-[10.9167rem] cursor-pointer",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold",
              r === "lastLogin" ? "text-white" : "text-white/60",
            ),
            children: "ÚLTIMO LOGIN",
          }),
          i.jsx("svg", {
            width: ".5625rem",
            height: ".3125rem",
            viewBox: "0 0 9 5",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            className: ne(r === "lastLogin" && s === "desc" && "rotate-180"),
            children: i.jsx("path", {
              "fill-rule": "evenodd",
              "clip-rule": "evenodd",
              d: "M4.9788 4.8085C4.8518 4.93112 4.67958 5 4.5 5C4.32042 5 4.1482 4.93112 4.0212 4.8085L0.190107 1.10845C0.0667439 0.985094 -0.0015173 0.819876 2.57492e-05 0.648382C0.00156879 0.476888 0.072793 0.31284 0.198358 0.191571C0.323921 0.0703025 0.493779 0.00151491 0.671347 2.47955e-05C0.848914 -0.00146532 1.01998 0.0644608 1.14771 0.183604L4.5 3.42123L7.85229 0.183604C7.98002 0.0644608 8.15109 -0.00146532 8.32865 2.47955e-05C8.50622 0.00151491 8.67608 0.0703025 8.80164 0.191571C8.92721 0.31284 8.99843 0.476888 8.99997 0.648382C9.00152 0.819876 8.93326 0.985094 8.80989 1.10845L4.9788 4.8085Z",
              fill: "white",
              "fill-opacity": "0.25",
            }),
          }),
        ],
      }),
    ],
  });
}
function B9({
  memberId: r,
  userId: s,
  canPromote: a,
  canDemote: c,
  canDismiss: d,
  onPromote: m,
  onDemote: x,
  onDismiss: h,
}) {
  const v = d || r === s;
  return i.jsxs("div", {
    className: "flex items-center justify-end flex-1 gap-1.5",
    children: [
      a &&
        i.jsx("button", {
          onClick: m,
          className: "hover:opacity-80 transition-opacity",
          children: i.jsxs("svg", {
            width: "1.25rem",
            height: "1.25rem",
            viewBox: "0 0 20 20",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
              i.jsx("rect", {
                width: "20",
                height: "20",
                rx: "4",
                fill: "#67C32E",
                "fill-opacity": "0.15",
              }),
              i.jsx("path", {
                d: "M12.9631 9.69792C13.0344 9.51458 13.0006 9.30208 12.8769 9.15625L10.3263 6.15625C10.2419 6.05625 10.1238 6 10 6C9.87622 6 9.75807 6.05625 9.67368 6.15625L7.12315 9.15625C6.99937 9.30208 6.96561 9.51458 7.03688 9.69792C7.10814 9.88125 7.26943 10 7.44946 10H8.79975V13.3333C8.79975 13.7021 9.06793 14 9.39987 14H10.6001C10.9321 14 11.2003 13.7021 11.2003 13.3333V10H12.5505C12.7306 10 12.8919 9.88125 12.9631 9.69792Z",
                fill: "#67C32E",
              }),
            ],
          }),
        }),
      c &&
        i.jsx("button", {
          onClick: x,
          className: "hover:opacity-80 transition-opacity",
          children: i.jsxs("svg", {
            width: "1.25rem",
            height: "1.25rem",
            viewBox: "0 0 20 20",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
              i.jsx("rect", {
                width: "20",
                height: "20",
                rx: "4",
                fill: "#ff4848ff",
                "fill-opacity": "0.15",
              }),
              i.jsx("path", {
                d: "M7.03688 10.3021C6.96561 10.4854 6.99937 10.6979 7.12315 10.8437L9.67368 13.8437C9.75807 13.9437 9.87622 14 10 14C10.1238 14 10.2419 13.9437 10.3263 13.8437L12.8769 10.8437C13.0006 10.6979 13.0344 10.4854 12.9631 10.3021C12.8919 10.1187 12.7306 10 12.5505 10L11.2003 10L11.2003 6.66667C11.2003 6.29792 10.9321 6 10.6001 6L9.39987 6C9.06793 6 8.79975 6.29792 8.79975 6.66667L8.79975 10L7.44946 10C7.26943 10 7.10814 10.1187 7.03688 10.3021Z",
                fill: "#ff4848ff",
              }),
            ],
          }),
        }),
      v &&
        i.jsx("button", {
          onClick: h,
          className: "hover:opacity-80 transition-opacity",
          children: i.jsxs("svg", {
            width: "1.25rem",
            height: "1.25rem",
            viewBox: "0 0 20 20",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
              i.jsx("rect", {
                width: "20",
                height: "20",
                rx: "4",
                fill: "#C33C2E",
                "fill-opacity": "0.15",
              }),
              i.jsx("path", {
                "fill-rule": "evenodd",
                "clip-rule": "evenodd",
                d: "M10.0046 11.0768L12.6987 13.7679C12.8416 13.9107 13.0355 13.9909 13.2377 13.9909C13.4399 13.9909 13.6338 13.9107 13.7767 13.7679C13.9197 13.6251 14 13.4314 14 13.2295C14 13.0275 13.9197 12.8338 13.7767 12.691L11.0816 10L13.7762 7.30895C13.847 7.23825 13.9031 7.15431 13.9414 7.06195C13.9796 6.96958 13.9993 6.87058 13.9993 6.77062C13.9993 6.67065 13.9796 6.57166 13.9412 6.47931C13.9029 6.38696 13.8468 6.30305 13.776 6.23238C13.7052 6.16171 13.6212 6.10566 13.5287 6.06742C13.4362 6.02919 13.3371 6.00952 13.237 6.00954C13.1369 6.00957 13.0378 6.02928 12.9454 6.06756C12.8529 6.10584 12.7689 6.16193 12.6982 6.23264L10.0046 8.92368L7.31044 6.23264C7.24018 6.1599 7.15611 6.10187 7.06316 6.06194C6.9702 6.022 6.87022 6.00096 6.76903 6.00003C6.66785 5.99911 6.56749 6.01832 6.47382 6.05655C6.38015 6.09478 6.29504 6.15126 6.22345 6.22269C6.15187 6.29413 6.09525 6.37909 6.05688 6.47262C6.01852 6.56615 5.99919 6.66637 6.00003 6.76744C6.00086 6.86851 6.02183 6.9684 6.06173 7.06129C6.10162 7.15417 6.15963 7.23819 6.23238 7.30845L8.92752 10L6.23289 12.6916C6.16014 12.7618 6.10213 12.8458 6.06223 12.9387C6.02234 13.0316 6.00136 13.1315 6.00053 13.2326C5.9997 13.3336 6.01903 13.4339 6.05739 13.5274C6.09575 13.6209 6.15238 13.7059 6.22396 13.7773C6.29555 13.8487 6.38066 13.9052 6.47433 13.9435C6.568 13.9817 6.66836 14.0009 6.76954 14C6.87073 13.999 6.97071 13.978 7.06367 13.9381C7.15662 13.8981 7.24068 13.8401 7.31095 13.7674L10.0046 11.0768Z",
                fill: "#C33C2E",
              }),
            ],
          }),
        }),
    ],
  });
}
function H9({
  member: r,
  userId: s,
  permissions: a,
  onPromote: c,
  onDemote: d,
  onDismiss: m,
}) {
  return i.jsxs("div", {
    className:
      "w-full h-10 bg-white/[.04] rounded-[.3125rem] flex items-center px-4 flex-none",
    children: [
      i.jsx("p", {
        className: "text-white text-xs font-medium w-[8rem]",
        children: r.id,
      }),
      i.jsxs("div", {
        className: "flex items-center gap-1.5 w-[10.9167rem]",
        children: [
          i.jsx("svg", {
            width: ".375rem",
            height: ".375rem",
            viewBox: "0 0 6 6",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M0 2.625L1.5 1.31954e-07L4.5 0L6 2.625L4.5 5.25L1.5 5.25L0 2.625Z",
              fill: r.status ? "#67C32E" : "white",
              "fill-opacity": r.status ? "1" : "0.2",
            }),
          }),
          i.jsx("p", {
            className: "text-white text-xs font-medium uppercase",
            children: r.name,
          }),
        ],
      }),
      i.jsxs("div", {
        className: "flex items-center gap-1.5 w-[10.9167rem]",
        children: [
          i.jsx("p", {
            className: "text-white text-xs font-medium",
            children: r.role,
          }),
          r.role_id === 1 &&
            i.jsxs("svg", {
              width: "1.125rem",
              height: "1rem",
              viewBox: "0 0 18 16",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: [
                i.jsx("path", {
                  d: "M0 7.875L4.5 3.95861e-07L13.5 0L18 7.875L13.5 15.75L4.5 15.75L0 7.875Z",
                  fill: "#ff4848ff",
                  "fill-opacity": "0.08",
                }),
                i.jsx("path", {
                  d: "M5.9375 9.5625L5.0625 4.92188L7.46875 7.03125L9 4.5L10.5312 7.03125L12.9375 4.92188L12.0625 9.5625H5.9375ZM12.0625 10.8281C12.0625 11.0813 11.8875 11.25 11.625 11.25H6.375C6.1125 11.25 5.9375 11.0813 5.9375 10.8281V10.4062H12.0625V10.8281Z",
                  fill: "#ff4848ff",
                }),
              ],
            }),
        ],
      }),
      i.jsx("p", {
        className:
          "text-white/65 text-xs font-medium text-center w-[10.9167rem]",
        children: r.lastLogin,
      }),
      i.jsx(B9, {
        memberId: r.id,
        userId: s,
        canPromote: (a == null ? void 0 : a.promote) || !1,
        canDemote: (a == null ? void 0 : a.demote) || !1,
        canDismiss: (a == null ? void 0 : a.dismiss) || !1,
        onPromote: c,
        onDemote: d,
        onDismiss: m,
      }),
    ],
  });
}
function V9() {
  const { permissions: r, user_id: s, warnings: a } = Ze(),
    [c, d] = p.useState(""),
    [m, x] = p.useState([]),
    [h, v] = p.useState("id"),
    [y, M] = p.useState("asc"),
    j = p.useMemo(() => {
      const N =
        m == null
          ? void 0
          : m.sort((k, P) => {
              let T = 0;
              return (
                h === "id"
                  ? (T = k.id - P.id)
                  : h === "name"
                    ? (T = k.name.localeCompare(P.name))
                    : h === "role"
                      ? (T = k.role_id - P.role_id)
                      : h === "lastLogin" &&
                        (T =
                          new Date(
                            ...k.lastLogin.split("/").reverse().map(Number),
                          ).getTime() -
                          new Date(
                            ...P.lastLogin.split("/").reverse().map(Number),
                          ).getTime()),
                y === "asc" ? T : -T
              );
            });
      return (
        (N == null
          ? void 0
          : N.filter(
              (k) =>
                String(k.name).toLowerCase().includes(c.toLowerCase()) ||
                String(k.id).includes(c.toLowerCase()),
            )) || []
      );
    }, [c, m, h, y]),
    b = p.useMemo(() => m.filter((N) => N.status).length, [m]);
  function O(N) {
    se("DeleteWarning", { index: N });
  }
  const H = (N) => {
    h === N ? M(y === "asc" ? "desc" : "asc") : (v(N), M("asc"));
  };
  return (
    p.useEffect(() => {
      se("GetMembers", {}, [
        {
          id: 1001,
          name: "THUNDER",
          role: "LÍDER",
          role_id: 1,
          lastLogin: "21/10/2024 ÁS 14:30:15",
          status: !0,
        },
        {
          id: 1002,
          name: "SHADOW",
          role: "GERENTE",
          role_id: 2,
          lastLogin: "21/10/2024 ÁS 12:15:42",
          status: !0,
        },
        {
          id: 1003,
          name: "PHOENIX",
          role: "GERENTE",
          role_id: 2,
          lastLogin: "20/10/2024 ÁS 23:45:18",
          status: !1,
        },
        {
          id: 1004,
          name: "VIPER",
          role: "SUPERVISOR",
          role_id: 3,
          lastLogin: "21/10/2024 ÁS 10:20:33",
          status: !0,
        },
        {
          id: 1005,
          name: "RAZOR",
          role: "SUPERVISOR",
          role_id: 3,
          lastLogin: "21/10/2024 ÁS 08:55:27",
          status: !0,
        },
        {
          id: 1006,
          name: "BLADE",
          role: "MEMBRO",
          role_id: 4,
          lastLogin: "19/10/2024 ÁS 19:30:12",
          status: !1,
        },
        {
          id: 1007,
          name: "GHOST",
          role: "MEMBRO",
          role_id: 4,
          lastLogin: "21/10/2024 ÁS 13:40:55",
          status: !0,
        },
        {
          id: 1008,
          name: "STORM",
          role: "MEMBRO",
          role_id: 4,
          lastLogin: "20/10/2024 ÁS 22:10:48",
          status: !1,
        },
        {
          id: 1009,
          name: "COBRA",
          role: "MEMBRO",
          role_id: 4,
          lastLogin: "21/10/2024 ÁS 11:25:36",
          status: !0,
        },
        {
          id: 1010,
          name: "WOLF",
          role: "MEMBRO",
          role_id: 4,
          lastLogin: "18/10/2024 ÁS 16:50:22",
          status: !1,
        },
        {
          id: 1011,
          name: "TIGER",
          role: "MEMBRO",
          role_id: 4,
          lastLogin: "21/10/2024 ÁS 09:15:44",
          status: !0,
        },
        {
          id: 1012,
          name: "HAWK",
          role: "RECRUTA",
          role_id: 5,
          lastLogin: "20/10/2024 ÁS 20:35:17",
          status: !1,
        },
        {
          id: 1013,
          name: "FALCON",
          role: "RECRUTA",
          role_id: 5,
          lastLogin: "21/10/2024 ÁS 15:20:09",
          status: !0,
        },
        {
          id: 1014,
          name: "PANTHER",
          role: "RECRUTA",
          role_id: 5,
          lastLogin: "19/10/2024 ÁS 18:45:31",
          status: !1,
        },
        {
          id: 1015,
          name: "RAVEN",
          role: "RECRUTA",
          role_id: 5,
          lastLogin: "21/10/2024 ÁS 07:30:58",
          status: !0,
        },
        {
          id: 1016,
          name: "DRAGON",
          role: "RECRUTA",
          role_id: 5,
          lastLogin: "17/10/2024 ÁS 21:15:46",
          status: !1,
        },
        {
          id: 1017,
          name: "LYNX",
          role: "RECRUTA",
          role_id: 5,
          lastLogin: "21/10/2024 ÁS 16:40:23",
          status: !0,
        },
        {
          id: 1018,
          name: "EAGLE",
          role: "RECRUTA",
          role_id: 5,
          lastLogin: "20/10/2024 ÁS 15:25:11",
          status: !1,
        },
        {
          id: 1019,
          name: "BULLET",
          role: "RECRUTA",
          role_id: 5,
          lastLogin: "21/10/2024 ÁS 12:50:37",
          status: !0,
        },
        {
          id: 1020,
          name: "SMOKE",
          role: "RECRUTA",
          role_id: 5,
          lastLogin: "16/10/2024 ÁS 14:10:52",
          status: !1,
        },
      ]).then(x);
    }, []),
    i.jsxs("div", {
      className: "size-full flex items-start gap-3 overflow-hidden",
      children: [
        i.jsxs("div", {
          className:
            "h-full w-[54.75rem] flex-none rounded-[.3125rem] border-[.0625rem] border-white/5 bg-white/[.01] p-4 flex flex-col gap-3 overflow-hidden",
          children: [
            i.jsx(T9, {
              membersCount: m.length,
              onlineCount: b,
              search: c,
              onSearchChange: d,
              canInvite: (r == null ? void 0 : r.invite) || !1,
            }),
            i.jsxs("div", {
              className: "w-full flex-1 overflow-hidden flex flex-col gap-2",
              children: [
                i.jsx(A9, { sortStyle: h, sortOrder: y, onToggleSort: H }),
                i.jsx("div", {
                  className: "w-full flex-1 flex flex-col gap-2 overflow-auto",
                  children: j.map((N) =>
                    i.jsx(
                      H9,
                      {
                        member: N,
                        userId: s,
                        permissions: {
                          promote: r == null ? void 0 : r.promote,
                          demote: r == null ? void 0 : r.demote,
                          dismiss: r == null ? void 0 : r.dismiss,
                        },
                        onPromote: () => {
                          se("PromoteMember", { id: N.id }).then((k) => {
                            k &&
                              x((P) =>
                                P == null
                                  ? void 0
                                  : P.map((T) =>
                                      T.id === N.id
                                        ? {
                                            ...T,
                                            role_id: k.role_id,
                                            role: k.role,
                                          }
                                        : T,
                                    ),
                              );
                          });
                        },
                        onDemote: () => {
                          se("DemoteMember", { id: N.id }).then((k) => {
                            k &&
                              x((P) =>
                                P == null
                                  ? void 0
                                  : P.map((T) =>
                                      T.id === N.id
                                        ? {
                                            ...T,
                                            role_id: k.role_id,
                                            role: k.role,
                                          }
                                        : T,
                                    ),
                              );
                          });
                        },
                        onDismiss: () => {
                          se("DimissMember", { id: N.id }, !0).then(() => {
                            x((k) =>
                              k == null
                                ? void 0
                                : k.filter((P) => P.id !== N.id),
                            );
                          });
                        },
                      },
                      N.id,
                    ),
                  ),
                }),
              ],
            }),
          ],
        }),
        i.jsx(D9, {
          warnings: a,
          isLeader: (r == null ? void 0 : r.leader) || !1,
          onDeleteWarning: O,
        }),
      ],
    })
  );
}
function z9() {
  const { setDiscord: r } = Ze(),
    s = p.useRef(null);
  function a() {
    var d;
    const c = (d = s.current) == null ? void 0 : d.value;
    se("SetConfig", { discord: c }).then(r);
  }
  return i.jsxs(jt, {
    children: [
      i.jsx(Nt, {
        children: i.jsx("button", {
          className:
            "w-[10rem] h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 flex items-center justify-center rounded-[.3125rem] text-[#151716] text-sm font-bold",
          children: "EDITAR",
        }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22rem] p-4 rounded-[.5625rem] flex flex-col gap-4 border-[.0563rem] border-white/10 bg-[#151716]",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2 w-full",
                children: [
                  i.jsx("svg", {
                    width: ".6875rem",
                    height: ".6875rem",
                    viewBox: "0 0 11 11",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      d: "M9.90811 4.00045C9.89816 3.94631 9.8775 3.8951 9.84754 3.85031C9.81757 3.80553 9.77901 3.76821 9.73446 3.74091L8.40286 2.92381L8.3975 1.30787C8.39734 1.25222 8.38596 1.19727 8.36415 1.14681C8.34234 1.09636 8.31061 1.0516 8.27117 1.01564C7.78814 0.575701 7.23189 0.23856 6.632 0.0221406C6.58476 0.00492378 6.53469 -0.00144772 6.48503 0.0034365C6.43536 0.00832072 6.38719 0.0243524 6.34363 0.0504988L5.00042 0.858947L3.65588 0.0490568C3.61229 0.0227632 3.56406 0.00661045 3.51431 0.00164286C3.46456 -0.00332473 3.41439 0.00300333 3.36706 0.020218C2.76753 0.238027 2.21189 0.576473 1.72968 1.01756C1.69029 1.05347 1.6586 1.09815 1.63679 1.14852C1.61498 1.19888 1.60357 1.25374 1.60335 1.30931L1.59665 2.92669L0.265049 3.74379C0.220499 3.7711 0.181932 3.80841 0.151969 3.8532C0.122005 3.89798 0.101348 3.94919 0.091401 4.00334C-0.030467 4.66273 -0.030467 5.34152 0.091401 6.00091C0.101348 6.05505 0.122005 6.10626 0.151969 6.15105C0.181932 6.19583 0.220499 6.23315 0.265049 6.26046L1.59665 7.07756L1.60201 8.69397C1.60217 8.74962 1.61355 8.80457 1.63536 8.85503C1.65717 8.90548 1.68889 8.95024 1.72834 8.98621C2.21137 9.42614 2.76762 9.76328 3.3675 9.9797C3.41475 9.99692 3.46481 10.0033 3.51448 9.99841C3.56415 9.99352 3.61231 9.97749 3.65588 9.95134L5.00042 9.14049L6.34497 9.95038C6.39818 9.9823 6.45815 9.99886 6.51906 9.99845C6.55807 9.99843 6.59681 9.99162 6.63379 9.97826C7.23316 9.76055 7.78877 9.42245 8.27117 8.98188C8.31056 8.94597 8.34225 8.90129 8.36405 8.85092C8.38586 8.80056 8.39727 8.7457 8.3975 8.69013L8.4042 7.07275L9.7358 6.25565C9.78035 6.22834 9.81891 6.19103 9.84888 6.14624C9.87884 6.10146 9.8995 6.05025 9.90944 5.9961C10.0306 5.33724 10.0302 4.65913 9.90811 4.00045ZM5.00042 6.92231C4.64727 6.92231 4.30204 6.80955 4.0084 6.59829C3.71477 6.38704 3.4859 6.08677 3.35076 5.73546C3.21561 5.38416 3.18025 4.99759 3.24915 4.62464C3.31804 4.2517 3.4881 3.90912 3.73782 3.64024C3.98754 3.37137 4.3057 3.18826 4.65207 3.11407C4.99844 3.03989 5.35746 3.07796 5.68374 3.22348C6.01001 3.369 6.28888 3.61542 6.48508 3.93159C6.68129 4.24776 6.78601 4.61947 6.78601 4.99972C6.78601 5.50962 6.59789 5.99864 6.26302 6.35919C5.92816 6.71975 5.47399 6.92231 5.00042 6.92231Z",
                      fill: "white",
                      "fill-opacity": "0.25",
                    }),
                  }),
                  i.jsx("h2", {
                    className: "text-white/65 text-sm font-bold",
                    children: "EDITAR LINK DO DISCORD",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "LINK DO DISCORD",
                  }),
                  i.jsx("input", {
                    ref: s,
                    type: "text",
                    placeholder: "DIGITE O LINK...",
                    className:
                      "w-full h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 text-white/35 text-xs font-medium rounded-[.3125rem] placeholder:text-white/35 outline-none",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx("button", {
                    onClick: a,
                    className:
                      "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                    children: "CONFIRMAR",
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function U9() {
  const { setPreset: r } = Ze(),
    s = p.useRef(null),
    a = p.useRef(null);
  function c() {
    var d, m;
    se("SetPreset", {
      male: (d = s.current) == null ? void 0 : d.value,
      female: (m = a.current) == null ? void 0 : m.value,
    }).then((x) => r({ male: x.male, female: x.female }));
  }
  return i.jsxs(jt, {
    children: [
      i.jsx(Nt, {
        children: i.jsx("button", {
          className:
            "w-[10rem] h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 flex items-center justify-center rounded-[.3125rem] text-[#151716] text-sm font-bold",
          children: "EDITAR",
        }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22rem] p-4 rounded-[.5625rem] flex flex-col gap-4 border-[.0563rem] border-white/10 bg-[#151716]",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2 w-full",
                children: [
                  i.jsx("svg", {
                    width: ".6875rem",
                    height: ".6875rem",
                    viewBox: "0 0 11 11",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      d: "M9.90811 4.00045C9.89816 3.94631 9.8775 3.8951 9.84754 3.85031C9.81757 3.80553 9.77901 3.76821 9.73446 3.74091L8.40286 2.92381L8.3975 1.30787C8.39734 1.25222 8.38596 1.19727 8.36415 1.14681C8.34234 1.09636 8.31061 1.0516 8.27117 1.01564C7.78814 0.575701 7.23189 0.23856 6.632 0.0221406C6.58476 0.00492378 6.53469 -0.00144772 6.48503 0.0034365C6.43536 0.00832072 6.38719 0.0243524 6.34363 0.0504988L5.00042 0.858947L3.65588 0.0490568C3.61229 0.0227632 3.56406 0.00661045 3.51431 0.00164286C3.46456 -0.00332473 3.41439 0.00300333 3.36706 0.020218C2.76753 0.238027 2.21189 0.576473 1.72968 1.01756C1.69029 1.05347 1.6586 1.09815 1.63679 1.14852C1.61498 1.19888 1.60357 1.25374 1.60335 1.30931L1.59665 2.92669L0.265049 3.74379C0.220499 3.7711 0.181932 3.80841 0.151969 3.8532C0.122005 3.89798 0.101348 3.94919 0.091401 4.00334C-0.030467 4.66273 -0.030467 5.34152 0.091401 6.00091C0.101348 6.05505 0.122005 6.10626 0.151969 6.15105C0.181932 6.19583 0.220499 6.23315 0.265049 6.26046L1.59665 7.07756L1.60201 8.69397C1.60217 8.74962 1.61355 8.80457 1.63536 8.85503C1.65717 8.90548 1.68889 8.95024 1.72834 8.98621C2.21137 9.42614 2.76762 9.76328 3.3675 9.9797C3.41475 9.99692 3.46481 10.0033 3.51448 9.99841C3.56415 9.99352 3.61231 9.97749 3.65588 9.95134L5.00042 9.14049L6.34497 9.95038C6.39818 9.9823 6.45815 9.99886 6.51906 9.99845C6.55807 9.99843 6.59681 9.99162 6.63379 9.97826C7.23316 9.76055 7.78877 9.42245 8.27117 8.98188C8.31056 8.94597 8.34225 8.90129 8.36405 8.85092C8.38586 8.80056 8.39727 8.7457 8.3975 8.69013L8.4042 7.07275L9.7358 6.25565C9.78035 6.22834 9.81891 6.19103 9.84888 6.14624C9.87884 6.10146 9.8995 6.05025 9.90944 5.9961C10.0306 5.33724 10.0302 4.65913 9.90811 4.00045ZM5.00042 6.92231C4.64727 6.92231 4.30204 6.80955 4.0084 6.59829C3.71477 6.38704 3.4859 6.08677 3.35076 5.73546C3.21561 5.38416 3.18025 4.99759 3.24915 4.62464C3.31804 4.2517 3.4881 3.90912 3.73782 3.64024C3.98754 3.37137 4.3057 3.18826 4.65207 3.11407C4.99844 3.03989 5.35746 3.07796 5.68374 3.22348C6.01001 3.369 6.28888 3.61542 6.48508 3.93159C6.68129 4.24776 6.78601 4.61947 6.78601 4.99972C6.78601 5.50962 6.59789 5.99864 6.26302 6.35919C5.92816 6.71975 5.47399 6.92231 5.00042 6.92231Z",
                      fill: "white",
                      "fill-opacity": "0.25",
                    }),
                  }),
                  i.jsx("h2", {
                    className: "text-white/65 text-sm font-bold",
                    children: "EDITAR PRESETS DE ROUPA",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "PRESET MASCULINO",
                  }),
                  i.jsx("input", {
                    ref: s,
                    type: "text",
                    placeholder: "DIGITE O PRESET MASCULINO...",
                    className:
                      "w-full h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 text-white/35 text-xs font-medium rounded-[.3125rem] placeholder:text-white/35 outline-none",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "PRESET FEMININO",
                  }),
                  i.jsx("input", {
                    ref: a,
                    type: "text",
                    placeholder: "DIGITE O PRESET FEMININO...",
                    className:
                      "w-full h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 text-white/35 text-xs font-medium rounded-[.3125rem] placeholder:text-white/35 outline-none",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx("button", {
                    onClick: c,
                    className:
                      "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                    children: "CONFIRMAR",
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function Z9() {
  const { setRadio: r } = Ze(),
    s = p.useRef(null);
  function a() {
    var c;
    se("SetRadio", {
      frequency: Number((c = s.current) == null ? void 0 : c.value),
    }).then(r);
  }
  return i.jsxs(jt, {
    children: [
      i.jsx(Nt, {
        children: i.jsx("button", {
          className:
            "w-[10rem] h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 flex items-center justify-center rounded-[.3125rem] text-[#151716] text-sm font-bold",
          children: "EDITAR",
        }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22rem] p-4 rounded-[.5625rem] flex flex-col gap-4 border-[.0563rem] border-white/10 bg-[#151716]",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2 w-full",
                children: [
                  i.jsx("svg", {
                    width: ".6875rem",
                    height: ".6875rem",
                    viewBox: "0 0 11 11",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      d: "M9.90811 4.00045C9.89816 3.94631 9.8775 3.8951 9.84754 3.85031C9.81757 3.80553 9.77901 3.76821 9.73446 3.74091L8.40286 2.92381L8.3975 1.30787C8.39734 1.25222 8.38596 1.19727 8.36415 1.14681C8.34234 1.09636 8.31061 1.0516 8.27117 1.01564C7.78814 0.575701 7.23189 0.23856 6.632 0.0221406C6.58476 0.00492378 6.53469 -0.00144772 6.48503 0.0034365C6.43536 0.00832072 6.38719 0.0243524 6.34363 0.0504988L5.00042 0.858947L3.65588 0.0490568C3.61229 0.0227632 3.56406 0.00661045 3.51431 0.00164286C3.46456 -0.00332473 3.41439 0.00300333 3.36706 0.020218C2.76753 0.238027 2.21189 0.576473 1.72968 1.01756C1.69029 1.05347 1.6586 1.09815 1.63679 1.14852C1.61498 1.19888 1.60357 1.25374 1.60335 1.30931L1.59665 2.92669L0.265049 3.74379C0.220499 3.7711 0.181932 3.80841 0.151969 3.8532C0.122005 3.89798 0.101348 3.94919 0.091401 4.00334C-0.030467 4.66273 -0.030467 5.34152 0.091401 6.00091C0.101348 6.05505 0.122005 6.10626 0.151969 6.15105C0.181932 6.19583 0.220499 6.23315 0.265049 6.26046L1.59665 7.07756L1.60201 8.69397C1.60217 8.74962 1.61355 8.80457 1.63536 8.85503C1.65717 8.90548 1.68889 8.95024 1.72834 8.98621C2.21137 9.42614 2.76762 9.76328 3.3675 9.9797C3.41475 9.99692 3.46481 10.0033 3.51448 9.99841C3.56415 9.99352 3.61231 9.97749 3.65588 9.95134L5.00042 9.14049L6.34497 9.95038C6.39818 9.9823 6.45815 9.99886 6.51906 9.99845C6.55807 9.99843 6.59681 9.99162 6.63379 9.97826C7.23316 9.76055 7.78877 9.42245 8.27117 8.98188C8.31056 8.94597 8.34225 8.90129 8.36405 8.85092C8.38586 8.80056 8.39727 8.7457 8.3975 8.69013L8.4042 7.07275L9.7358 6.25565C9.78035 6.22834 9.81891 6.19103 9.84888 6.14624C9.87884 6.10146 9.8995 6.05025 9.90944 5.9961C10.0306 5.33724 10.0302 4.65913 9.90811 4.00045ZM5.00042 6.92231C4.64727 6.92231 4.30204 6.80955 4.0084 6.59829C3.71477 6.38704 3.4859 6.08677 3.35076 5.73546C3.21561 5.38416 3.18025 4.99759 3.24915 4.62464C3.31804 4.2517 3.4881 3.90912 3.73782 3.64024C3.98754 3.37137 4.3057 3.18826 4.65207 3.11407C4.99844 3.03989 5.35746 3.07796 5.68374 3.22348C6.01001 3.369 6.28888 3.61542 6.48508 3.93159C6.68129 4.24776 6.78601 4.61947 6.78601 4.99972C6.78601 5.50962 6.59789 5.99864 6.26302 6.35919C5.92816 6.71975 5.47399 6.92231 5.00042 6.92231Z",
                      fill: "white",
                      "fill-opacity": "0.25",
                    }),
                  }),
                  i.jsx("h2", {
                    className: "text-white/65 text-sm font-bold",
                    children: "EDITAR FREQUÊNCIA DE RÁDIO",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "FREQUÊNCIA (MHZ)",
                  }),
                  i.jsx("input", {
                    ref: s,
                    type: "number",
                    placeholder: "DIGITE A FREQUÊNCIA...",
                    className:
                      "w-full h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 text-white/35 text-xs font-medium rounded-[.3125rem] placeholder:text-white/35 outline-none",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx("button", {
                    onClick: a,
                    className:
                      "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                    children: "CONFIRMAR",
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function Ma({ title: r, children: s }) {
  return i.jsxs("div", {
    className: "w-full flex items-center justify-between",
    children: [
      i.jsxs("div", {
        className: "flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".625rem",
            height: ".625rem",
            viewBox: "0 0 10 10",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M9.90811 4.00045C9.89816 3.94631 9.8775 3.8951 9.84754 3.85031C9.81757 3.80553 9.77901 3.76821 9.73446 3.74091L8.40286 2.92381L8.3975 1.30787C8.39734 1.25222 8.38596 1.19727 8.36415 1.14681C8.34234 1.09636 8.31061 1.0516 8.27117 1.01564C7.78814 0.575701 7.23189 0.23856 6.632 0.0221406C6.58476 0.00492378 6.53469 -0.00144772 6.48503 0.0034365C6.43536 0.00832072 6.38719 0.0243524 6.34363 0.0504988L5.00042 0.858947L3.65588 0.0490568C3.61229 0.0227632 3.56406 0.00661045 3.51431 0.00164286C3.46456 -0.00332473 3.41439 0.00300333 3.36706 0.020218C2.76753 0.238027 2.21189 0.576473 1.72968 1.01756C1.69029 1.05347 1.6586 1.09815 1.63679 1.14852C1.61498 1.19888 1.60357 1.25374 1.60335 1.30931L1.59665 2.92669L0.265049 3.74379C0.220499 3.7711 0.181932 3.80841 0.151969 3.8532C0.122005 3.89798 0.101348 3.94919 0.091401 4.00334C-0.030467 4.66273 -0.030467 5.34152 0.091401 6.00091C0.101348 6.05505 0.122005 6.10626 0.151969 6.15105C0.181932 6.19583 0.220499 6.23315 0.265049 6.26046L1.59665 7.07756L1.60201 8.69397C1.60217 8.74962 1.61355 8.80457 1.63536 8.85503C1.65717 8.90548 1.68889 8.95024 1.72834 8.98621C2.21137 9.42614 2.76762 9.76328 3.3675 9.9797C3.41475 9.99692 3.46481 10.0033 3.51448 9.99841C3.56415 9.99352 3.61231 9.97749 3.65588 9.95134L5.00042 9.14049L6.34497 9.95038C6.39818 9.9823 6.45815 9.99886 6.51906 9.99845C6.55807 9.99843 6.59681 9.99162 6.63379 9.97826C7.23316 9.76055 7.88877 9.42245 8.27117 8.98188C8.31056 8.94597 8.34225 8.90129 8.36405 8.85092C8.38586 8.80056 8.39727 8.7457 8.3975 8.69013L8.4042 7.07275L9.7358 6.25565C9.78035 6.22834 9.81891 6.19103 9.84888 6.14624C9.87884 6.10146 9.8995 6.05025 9.90944 5.9961C10.0306 5.33724 10.0302 4.65913 9.90811 4.00045ZM5.00042 6.92231C4.64727 6.92231 4.30204 6.80955 4.0084 6.59829C3.71477 6.38704 3.4859 6.08677 3.35076 5.73546C3.21561 5.38416 3.18025 4.99759 3.24915 4.62464C3.31804 4.2517 3.4881 3.90912 3.73782 3.64024C3.98754 3.37137 4.3057 3.18826 4.65207 3.11407C4.99844 3.03989 5.35746 3.07796 5.68374 3.22348C6.01001 3.369 6.28888 3.61542 6.48508 3.93159C6.68129 4.24776 6.78601 4.61947 6.78601 4.99972C6.78601 5.50962 6.59789 5.99864 6.26302 6.35919C5.92816 6.71975 5.47399 6.92231 5.00042 6.92231Z",
              fill: "white",
              "fill-opacity": "0.25",
            }),
          }),
          i.jsx("h2", {
            className: "text-white text-xs font-bold",
            children: r,
          }),
        ],
      }),
      s,
    ],
  });
}
function ba() {
  return i.jsxs("div", {
    className:
      "w-[15rem] h-8 bg-white/[.02] border-[.0625rem] border-white/5 rounded-[.3125rem] px-4 flex items-center gap-2",
    children: [
      i.jsx("svg", {
        width: ".75rem",
        height: ".75rem",
        viewBox: "0 0 12 12",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        children: i.jsx("path", {
          d: "M9.46992 8.63464L12 11.1641L11.1641 12L8.63464 9.46992C7.69346 10.2244 6.52279 10.6348 5.31653 10.6331C2.38181 10.6331 0 8.25126 0 5.31653C0 2.38181 2.38181 0 5.31653 0C8.25126 0 10.6331 2.38181 10.6331 5.31653C10.6348 6.52279 10.2244 7.69346 9.46992 8.63464ZM8.28493 8.19632C9.03446 7.42525 9.45312 6.39187 9.45161 5.31653C9.45161 3.03219 7.60087 1.18145 5.31653 1.18145C3.03219 1.18145 1.18145 3.03219 1.18145 5.31653C1.18145 7.60087 3.03219 9.45161 5.31653 9.45161C6.39187 9.45312 7.42525 9.03446 8.19632 8.28493L8.28493 8.19632Z",
          fill: "white",
          fillOpacity: "0.25",
        }),
      }),
      i.jsx("input", {
        type: "text",
        name: "search",
        id: "search",
        placeholder: "PESQUISAR...",
        className:
          "text-white/45 text-xs font-semibold placeholder:text-white/45 flex-1 bg-transparent outline-none border-none",
      }),
    ],
  });
}
function D0({ label: r, prefix: s, value: a, editor: c }) {
  return i.jsxs("div", {
    className:
      "w-full h-12 bg-white/[.02] rounded-[.3125rem] px-4 flex items-center justify-between",
    children: [
      i.jsx("p", {
        className: "text-white text-[.8125rem] font-semibold",
        children: r,
      }),
      i.jsxs("div", {
        className: "flex items-center gap-3",
        children: [
          (s || a) &&
            i.jsxs("div", {
              className:
                "w-[25.75rem] h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 flex items-center justify-between rounded-[.3125rem]",
              children: [
                s &&
                  i.jsx("p", {
                    className: "text-white/35 text-xs font-normal",
                    children: s,
                  }),
                a &&
                  i.jsx("p", {
                    className: "text-white/65 text-xs font-normal",
                    children: a,
                  }),
              ],
            }),
          c,
        ],
      }),
    ],
  });
}
const Pa = {
  invite: { name: "Convidar", status: !1 },
  demote: { name: "Rebaixar", status: !0 },
  promote: { name: "Promover", status: !1 },
  dismiss: { name: "Demitir", status: !1 },
  withdraw: { name: "Sacar dinheiro", status: !1 },
  deposit: { name: "Depositar dinheiro", status: !1 },
  message: { name: "Escrever anotações", status: !1 },
  alerts: { name: "Escrever Alertas", status: !0 },
  chat: { name: "Escrever no chat", status: !1 },
};
function W9({ roleEdit: r }) {
  const [s, a] = p.useState({});
  p.useEffect(() => {
    se("GetPermissions", { roleEdit: r }, Pa).then(a);
  }, [r]);
  function c(m) {
    a((x) => ({ ...x, [m]: { ...x[m], status: !x[m].status } }));
  }
  function d() {
    se("SetPermissions", { role: r, permissions: s });
  }
  return i.jsxs(jt, {
    children: [
      i.jsx(Nt, {
        children: i.jsx("button", {
          className:
            "w-[10.5rem] h-[1.625rem] bg-white/[.03] rounded-[.3125rem] text-white/35 text-xs font-bold",
          children: "EDITAR PERMISSÕES",
        }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22rem] p-4 rounded-[.5625rem] flex flex-col gap-4 border-[.0563rem] border-white/10 bg-[#151716]",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2 w-full",
                children: [
                  i.jsx("svg", {
                    width: ".6875rem",
                    height: ".6875rem",
                    viewBox: "0 0 11 11",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      d: "M9.90811 4.00045C9.89816 3.94631 9.8775 3.8951 9.84754 3.85031C9.81757 3.80553 9.77901 3.76821 9.73446 3.74091L8.40286 2.92381L8.3975 1.30787C8.39734 1.25222 8.38596 1.19727 8.36415 1.14681C8.34234 1.09636 8.31061 1.0516 8.27117 1.01564C7.78814 0.575701 7.23189 0.23856 6.632 0.0221406C6.58476 0.00492378 6.53469 -0.00144772 6.48503 0.0034365C6.43536 0.00832072 6.38719 0.0243524 6.34363 0.0504988L5.00042 0.858947L3.65588 0.0490568C3.61229 0.0227632 3.56406 0.00661045 3.51431 0.00164286C3.46456 -0.00332473 3.41439 0.00300333 3.36706 0.020218C2.76753 0.238027 2.21189 0.576473 1.72968 1.01756C1.69029 1.05347 1.6586 1.09815 1.63679 1.14852C1.61498 1.19888 1.60357 1.25374 1.60335 1.30931L1.59665 2.92669L0.265049 3.74379C0.220499 3.7711 0.181932 3.80841 0.151969 3.8532C0.122005 3.89798 0.101348 3.94919 0.091401 4.00334C-0.030467 4.66273 -0.030467 5.34152 0.091401 6.00091C0.101348 6.05505 0.122005 6.10626 0.151969 6.15105C0.181932 6.19583 0.220499 6.23315 0.265049 6.26046L1.59665 7.07756L1.60201 8.69397C1.60217 8.74962 1.61355 8.80457 1.63536 8.85503C1.65717 8.90548 1.68889 8.95024 1.72834 8.98621C2.21137 9.42614 2.76762 9.76328 3.3675 9.9797C3.41475 9.99692 3.46481 10.0033 3.51448 9.99841C3.56415 9.99352 3.61231 9.97749 3.65588 9.95134L5.00042 9.14049L6.34497 9.95038C6.39818 9.9823 6.45815 9.99886 6.51906 9.99845C6.55807 9.99843 6.59681 9.99162 6.63379 9.97826C7.23316 9.76055 7.78877 9.42245 8.27117 8.98188C8.31056 8.94597 8.34225 8.90129 8.36405 8.85092C8.38586 8.80056 8.39727 8.7457 8.3975 8.69013L8.4042 7.07275L9.7358 6.25565C9.78035 6.22834 9.81891 6.19103 9.84888 6.14624C9.87884 6.10146 9.8995 6.05025 9.90944 5.9961C10.0306 5.33724 10.0302 4.65913 9.90811 4.00045ZM5.00042 6.92231C4.64727 6.92231 4.30204 6.80955 4.0084 6.59829C3.71477 6.38704 3.4859 6.08677 3.35076 5.73546C3.21561 5.38416 3.18025 4.99759 3.24915 4.62464C3.31804 4.2517 3.4881 3.90912 3.73782 3.64024C3.98754 3.37137 4.3057 3.18826 4.65207 3.11407C4.99844 3.03989 5.35746 3.07796 5.68374 3.22348C6.01001 3.369 6.28888 3.61542 6.48508 3.93159C6.68129 4.24776 6.78601 4.61947 6.78601 4.99972C6.78601 5.50962 6.59789 5.99864 6.26302 6.35919C5.92816 6.71975 5.47399 6.92231 5.00042 6.92231Z",
                      fill: "white",
                      "fill-opacity": "0.25",
                    }),
                  }),
                  i.jsx("h2", {
                    className: "text-white text-sm font-bold",
                    children: "EDITAR PERMISSÕES",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/60 text-xs font-semibold",
                    children: "PERMISSÕES",
                  }),
                  i.jsx("div", {
                    className: "flex flex-col gap-3",
                    children: Object.keys(s).map((m) => {
                      var x, h, v, y;
                      return i.jsxs(
                        "button",
                        {
                          onClick: () => c(m),
                          className: "flex items-center gap-3 cursor-pointer",
                          children: [
                            i.jsxs("div", {
                              className: "relative",
                              children: [
                                i.jsx("svg", {
                                  width: "22",
                                  height: "18",
                                  viewBox: "0 0 22 18",
                                  fill: "none",
                                  xmlns: "http://www.w3.org/2000/svg",
                                  children: i.jsx("path", {
                                    d: "M0 9L5.5 4.52413e-07L16.5 0L22 9L16.5 18L5.5 18L0 9Z",
                                    fill:
                                      (x = s[m]) != null && x.status
                                        ? "#ff4848ff"
                                        : "white",
                                    fillOpacity:
                                      (h = s[m]) != null && h.status
                                        ? "1"
                                        : "0.05",
                                  }),
                                }),
                                ((v = s[m]) == null ? void 0 : v.status) &&
                                  i.jsx("svg", {
                                    className:
                                      "absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2",
                                    width: "10",
                                    height: "8",
                                    viewBox: "0 0 10 8",
                                    fill: "none",
                                    xmlns: "http://www.w3.org/2000/svg",
                                    children: i.jsx("path", {
                                      d: "M1 4L3.5 6.5L9 1",
                                      stroke: "#1E1E1E",
                                      strokeWidth: "2",
                                      strokeLinecap: "round",
                                      strokeLinejoin: "round",
                                    }),
                                  }),
                              ],
                            }),
                            i.jsx("span", {
                              className:
                                "text-white text-xs font-semibold uppercase",
                              children: (y = Pa[m]) == null ? void 0 : y.name,
                            }),
                          ],
                        },
                        m,
                      );
                    }),
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx(qe, {
                    asChild: !0,
                    children: i.jsx("button", {
                      onClick: d,
                      className:
                        "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                      children: "SALVAR",
                    }),
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function $9({ roles: r }) {
  var s;
  return i.jsxs("div", {
    className: "w-full flex-1 flex flex-col gap-2 overflow-hidden",
    children: [
      i.jsxs("div", {
        className: "w-full h-8 bg-white/[.02] flex items-center px-4",
        children: [
          i.jsx("p", {
            className: "text-white/60 text-xs font-semibold w-[8rem]",
            children: "#",
          }),
          i.jsx("p", {
            className: "text-white/60 text-xs font-semibold w-[23.9583rem]",
            children: "CARGO",
          }),
          i.jsx("p", {
            className:
              "text-white/60 text-xs font-semibold w-[23.9583rem] text-center",
            children: "MEMBROS",
          }),
          i.jsx("p", {
            className:
              "text-white/60 text-xs font-semibold w-[23.9583rem] text-center",
            children: "PERMISSÕES",
          }),
        ],
      }),
      i.jsx("div", {
        className: "w-full flex-1 flex flex-col gap-2 overflow-y-auto",
        children:
          (s = r == null ? void 0 : r.sort((a, c) => a.nivel - c.nivel)) == null
            ? void 0
            : s.map((a, c) =>
                i.jsxs(
                  "div",
                  {
                    className:
                      "w-full h-[2.25rem] bg-white/[.04] flex items-center px-4 flex-none",
                    children: [
                      i.jsx("p", {
                        className: "text-white text-xs font-medium w-[8rem]",
                        children: c,
                      }),
                      i.jsxs("div", {
                        className: "flex items-center gap-1.5 w-[23.9583rem]",
                        children: [
                          i.jsx("p", {
                            className: "text-white text-xs font-semibold",
                            children: a.group,
                          }),
                          c === 0 &&
                            i.jsxs("svg", {
                              width: "1.125rem",
                              height: "1rem",
                              viewBox: "0 0 18 16",
                              fill: "none",
                              xmlns: "http://www.w3.org/2000/svg",
                              children: [
                                i.jsx("path", {
                                  d: "M0 7.875L4.5 3.95861e-07L13.5 0L18 7.875L13.5 15.75L4.5 15.75L0 7.875Z",
                                  fill: "#ff4848ff",
                                  "fill-opacity": "0.08",
                                }),
                                i.jsx("path", {
                                  d: "M5.9375 9.5625L5.0625 4.92188L7.46875 7.03125L9 4.5L10.5312 7.03125L12.9375 4.92188L12.0625 9.5625H5.9375ZM12.0625 10.8281C12.0625 11.0813 11.8875 11.25 11.625 11.25H6.375C6.1125 11.25 5.9375 11.0813 5.9375 10.8281V10.4062H12.0625V10.8281Z",
                                  fill: "#ff4848ff",
                                }),
                              ],
                            }),
                        ],
                      }),
                      i.jsx("p", {
                        className:
                          "text-white/65 text-xs font-medium w-[23.9583rem] text-center",
                        children: a.members,
                      }),
                      i.jsx("div", {
                        className:
                          "flex items-center justify-center w-[23.9583rem]",
                        children: i.jsx(W9, { roleEdit: a.group }),
                      }),
                    ],
                  },
                  c,
                ),
              ),
      }),
    ],
  });
}
function G9() {
  const { roles: r, discord: s, radio: a } = Ze();
  return i.jsxs("div", {
    className: "size-full flex flex-col gap-3 overflow-hidden",
    children: [
      i.jsxs("div", {
        className:
          "w-full bg-white/[.01] border-[.0625rem] border-white/5 p-4 flex flex-col gap-2",
        children: [
          i.jsx(Ma, { title: "AJUSTES", children: i.jsx(ba, {}) }),
          i.jsx(D0, {
            label: "DISCORD",
            prefix: "discord.gg/",
            value: s,
            editor: i.jsx(z9, {}),
          }),
          i.jsx(D0, {
            label: "RÁDIO",
            prefix: "MHZ",
            value: a,
            editor: i.jsx(Z9, {}),
          }),
          i.jsx(D0, { label: "PRESET DE ROUPA", editor: i.jsx(U9, {}) }),
        ],
      }),
      i.jsxs("div", {
        className:
          "w-full flex-1 bg-white/[.01] border-[.0625rem] border-white/5 p-4 flex flex-col gap-2 overflow-hidden",
        children: [
          i.jsx(Ma, { title: "PERMISSÕES", children: i.jsx(ba, {}) }),
          i.jsx($9, { roles: r }),
        ],
      }),
    ],
  });
}
function Q9() {
  const { setPartners: r } = Ze(),
    [s, a] = p.useState(!1),
    [c, d] = p.useState(""),
    [m, x] = p.useState(""),
    [h, v] = p.useState("");
  function y() {
    se("GetCDS", {}, "").then(d);
  }
  function M() {
    se(
      "NewPartner",
      { cds: c, note: 0, name: m, keyword: h, description: "", icon: "" },
      [],
    ).then((j) => {
      (r(j), x(""), v(""), d(""), a(!1));
    });
  }
  return i.jsxs(jt, {
    open: s,
    onOpenChange: a,
    children: [
      i.jsx(Nt, {
        asChild: !0,
        children: i.jsxs("button", {
          className:
            "w-[10rem] h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 flex items-center justify-center gap-2 rounded-[.3125rem] text-[#151716] text-sm font-bold",
          children: [
            i.jsx("svg", {
              width: ".75rem",
              height: ".75rem",
              viewBox: "0 0 12 12",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: i.jsx("path", {
                d: "M11.25 5.25H6.75V0.75C6.75 0.551088 6.67098 0.360322 6.53033 0.21967C6.38968 0.0790178 6.19891 0 6 0C5.80109 0 5.61032 0.0790178 5.46967 0.21967C5.32902 0.360322 5.25 0.551088 5.25 0.75V5.25H0.75C0.551088 5.25 0.360322 5.32902 0.21967 5.46967C0.0790178 5.61032 0 5.80109 0 6C0 6.19891 0.0790178 6.38968 0.21967 6.53033C0.360322 6.67098 0.551088 6.75 0.75 6.75H5.25V11.25C5.25 11.4489 5.32902 11.6397 5.46967 11.7803C5.61032 11.921 5.80109 12 6 12C6.19891 12 6.38968 11.921 6.53033 11.7803C6.67098 11.6397 6.75 11.4489 6.75 11.25V6.75H11.25C11.4489 6.75 11.6397 6.67098 11.7803 6.53033C11.921 6.38968 12 6.19891 12 6C12 5.80109 11.921 5.61032 11.7803 5.46967C11.6397 5.32902 11.4489 5.25 11.25 5.25Z",
                fill: "#151716",
              }),
            }),
            "ADICIONAR",
          ],
        }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22rem] p-4 rounded-[.5625rem] flex flex-col gap-4 border-[.0563rem] border-white/10 bg-[#151716]",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2 w-full",
                children: [
                  i.jsx("svg", {
                    width: ".6875rem",
                    height: ".6875rem",
                    viewBox: "0 0 11 11",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      d: "M4.92593 2.06207H6.64813L8.53681 0.16963C8.59017 0.11588 8.65366 0.0732177 8.72362 0.0441035C8.79357 0.0149894 8.86861 0 8.94439 0C9.02017 0 9.09521 0.0149894 9.16516 0.0441035C9.23512 0.0732177 9.29861 0.11588 9.35198 0.16963L10.8331 1.65491C10.94 1.76235 11 1.9077 11 2.0592C11 2.2107 10.94 2.35605 10.8331 2.4635L9.51846 3.78247H4.92593V4.9294C4.92593 5.08149 4.86545 5.22736 4.75779 5.3349C4.65014 5.44245 4.50412 5.50287 4.35187 5.50287C4.19962 5.50287 4.0536 5.44245 3.94594 5.3349C3.83829 5.22736 3.7778 5.08149 3.7778 4.9294V3.209C3.7778 2.90482 3.89877 2.61309 4.11408 2.398C4.3294 2.18291 4.62143 2.06207 4.92593 2.06207ZM1.48154 4.9294V7.22327L0.166934 8.5365C0.0600138 8.64395 0 8.7893 0 8.9408C0 9.0923 0.0600138 9.23765 0.166934 9.34509L1.64802 10.8304C1.70139 10.8841 1.76488 10.9268 1.83484 10.9559C1.90479 10.985 1.97983 11 2.05561 11C2.13139 11 2.20643 10.985 2.27638 10.9559C2.34634 10.9268 2.40983 10.8841 2.46319 10.8304L4.92593 8.3702H7.2222C7.37445 8.3702 7.52046 8.30978 7.62812 8.20224C7.73578 8.09469 7.79626 7.94883 7.79626 7.79673V7.22327H8.37033C8.52258 7.22327 8.66859 7.16285 8.77625 7.0553C8.88391 6.94776 8.94439 6.80189 8.94439 6.6498V6.07633H9.51846C9.67071 6.07633 9.81672 6.01592 9.92438 5.90837C10.032 5.80082 10.0925 5.65496 10.0925 5.50287V4.9294H6.07406V5.50287C6.07406 5.80705 5.9531 6.09878 5.73778 6.31387C5.52247 6.52896 5.23044 6.6498 4.92593 6.6498H3.7778C3.4733 6.6498 3.18127 6.52896 2.96595 6.31387C2.75064 6.09878 2.62967 5.80705 2.62967 5.50287V3.78247L1.48154 4.9294Z",
                      fill: "white",
                      "fill-opacity": "0.25",
                    }),
                  }),
                  i.jsx("h2", {
                    className: "text-white/65 text-sm font-bold",
                    children: "ADICIONAR PARCERIA",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "NOME DA FACÇÃO",
                  }),
                  i.jsx("input", {
                    type: "text",
                    value: m,
                    onChange: (j) => x(j.target.value),
                    placeholder: "DIGITE O NOME...",
                    className:
                      "w-full h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 text-white/35 text-xs font-medium rounded-[.3125rem] placeholder:text-white/35",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "PALAVRA CHAVE",
                  }),
                  i.jsx("input", {
                    type: "text",
                    value: h,
                    onChange: (j) => v(j.target.value),
                    placeholder: "DIGITE A PALAVRA CHAVE...",
                    className:
                      "w-full h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 text-white/35 text-xs font-medium rounded-[.3125rem] placeholder:text-white/35",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "LOCALIZAÇÃO",
                  }),
                  i.jsxs("div", {
                    className: "w-full flex items-center gap-1.5",
                    children: [
                      i.jsx("input", {
                        type: "text",
                        value: c,
                        onChange: (j) => d(j.target.value),
                        placeholder: "-1934.4, 13.65, -43.123",
                        className:
                          "flex-1 h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 text-white/35 text-xs font-medium rounded-[.3125rem] placeholder:text-white/35",
                      }),
                      i.jsx("button", {
                        onClick: y,
                        className:
                          "w-[3rem] h-8 flex items-center justify-center bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                        children: i.jsx("svg", {
                          width: ".8125rem",
                          height: "1rem",
                          viewBox: "0 0 13 16",
                          fill: "none",
                          xmlns: "http://www.w3.org/2000/svg",
                          children: i.jsx("path", {
                            d: "M6.5 8C6.03958 8 5.65392 7.8464 5.343 7.5392C5.03208 7.232 4.87608 6.85227 4.875 6.4C4.87392 5.94773 5.02992 5.568 5.343 5.2608C5.65608 4.9536 6.04175 4.8 6.5 4.8C6.95825 4.8 7.34446 4.9536 7.65862 5.2608C7.97279 5.568 8.12825 5.94773 8.125 6.4C8.12175 6.85227 7.96575 7.23253 7.657 7.5408C7.34825 7.84907 6.96258 8.00213 6.5 8ZM6.5 16C8.69375 14.16 10.3258 12.4603 11.3961 10.9008C12.4665 9.34133 13.0011 7.8944 13 6.56C13 4.56 12.343 2.96693 11.0289 1.7808C9.71479 0.594668 8.20517 0.0010681 6.5 1.43498e-06C4.79483 -0.00106523 3.28521 0.592535 1.97113 1.7808C0.657042 2.96907 0 4.56214 0 6.56C0 7.89333 0.535166 9.34027 1.6055 10.9008C2.67583 12.4613 4.30733 14.1611 6.5 16Z",
                            fill: "#151716",
                          }),
                        }),
                      }),
                    ],
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx("button", {
                    onClick: M,
                    className:
                      "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                    children: "CONFIRMAR",
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function K9({ search: r, setSearch: s, partnersCount: a }) {
  return i.jsxs("div", {
    className: "w-full flex items-center justify-between",
    children: [
      i.jsxs("div", {
        className: "flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".625rem",
            height: ".625rem",
            viewBox: "0 0 10 10",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M4.47812 1.87461H6.04375L7.76073 0.154209C7.80925 0.105346 7.86697 0.0665615 7.93056 0.0400941C7.99416 0.0136267 8.06237 0 8.13126 0C8.20016 0 8.26837 0.0136267 8.33197 0.0400941C8.39556 0.0665615 8.45328 0.105346 8.5018 0.154209L9.84824 1.50446C9.94544 1.60214 10 1.73427 10 1.872C10 2.00973 9.94544 2.14186 9.84824 2.23954L8.65314 3.43861H4.47812V4.48127C4.47812 4.61954 4.42314 4.75214 4.32527 4.84991C4.2274 4.94768 4.09466 5.00261 3.95624 5.00261C3.81783 5.00261 3.68509 4.94768 3.58722 4.84991C3.48935 4.75214 3.43437 4.61954 3.43437 4.48127V2.91727C3.43437 2.64074 3.54433 2.37554 3.74008 2.18C3.93582 1.98446 4.2013 1.87461 4.47812 1.87461ZM1.34686 4.48127V6.56661L0.151758 7.76046C0.054558 7.85814 0 7.99027 0 8.128C0 8.26573 0.054558 8.39786 0.151758 8.49554L1.4982 9.84579C1.54672 9.89466 1.60444 9.93344 1.66803 9.95991C1.73163 9.98637 1.79984 10 1.86873 10C1.93763 10 2.00584 9.98637 2.06944 9.95991C2.13303 9.93344 2.19075 9.89466 2.23927 9.84579L4.47812 7.60927H6.56563C6.70404 7.60927 6.83678 7.55435 6.93466 7.45658C7.03253 7.35881 7.08751 7.2262 7.08751 7.08794V6.56661H7.60939C7.7478 6.56661 7.88054 6.51168 7.97841 6.41391C8.07628 6.31614 8.13126 6.18354 8.13126 6.04527V5.52394H8.65314C8.79155 5.52394 8.92429 5.46901 9.02217 5.37124C9.12004 5.27348 9.17502 5.14087 9.17502 5.00261V4.48127H5.52188V5.00261C5.52188 5.27914 5.41191 5.54434 5.21617 5.73988C5.02043 5.93542 4.75494 6.04527 4.47812 6.04527H3.43437C3.15755 6.04527 2.89206 5.93542 2.69632 5.73988C2.50058 5.54434 2.39061 5.27914 2.39061 5.00261V3.43861L1.34686 4.48127Z",
              fill: "white",
              "fill-opacity": "0.25",
            }),
          }),
          i.jsx("h2", {
            className: "text-white text-xs font-bold",
            children: "PARCEIROS",
          }),
          i.jsx("p", {
            className:
              "text-white/50 text-xs font-normal h-[1.375rem] flex items-center justify-center bg-white/5 border-[.0625rem] border-white/[.03] px-2 rounded-[.3125rem]",
            children: a,
          }),
        ],
      }),
      i.jsxs("div", {
        className: "flex items-center gap-3",
        children: [
          i.jsxs("div", {
            className:
              "w-[15rem] h-8 bg-white/[.02] border-[.0625rem] border-white/5 rounded-[.3125rem] px-4 flex items-center gap-2",
            children: [
              i.jsx("svg", {
                width: ".75rem",
                height: ".75rem",
                viewBox: "0 0 12 12",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                children: i.jsx("path", {
                  d: "M9.46992 8.63464L12 11.1641L11.1641 12L8.63464 9.46992C7.69346 10.2244 6.52279 10.6348 5.31653 10.6331C2.38181 10.6331 0 8.25126 0 5.31653C0 2.38181 2.38181 0 5.31653 0C8.25126 0 10.6331 2.38181 10.6331 5.31653C10.6348 6.52279 10.2244 7.69346 9.46992 8.63464ZM8.28493 8.19632C9.03446 7.42525 9.45312 6.39187 9.45161 5.31653C9.45161 3.03219 7.60087 1.18145 5.31653 1.18145C3.03219 1.18145 1.18145 3.03219 1.18145 5.31653C1.18145 7.60087 3.03219 9.45161 5.31653 9.45161C6.39187 9.45312 7.42525 9.03446 8.19632 8.28493L8.28493 8.19632Z",
                  fill: "white",
                  fillOpacity: "0.25",
                }),
              }),
              i.jsx("input", {
                type: "text",
                name: "search",
                id: "search",
                value: r,
                onChange: (c) => s(c.target.value),
                placeholder: "PESQUISAR...",
                className:
                  "text-white/45 text-xs font-semibold placeholder:text-white/45 flex-1 bg-transparent outline-none border-none",
              }),
            ],
          }),
          i.jsx(Q9, {}),
        ],
      }),
    ],
  });
}
function Y9() {
  return i.jsxs("svg", {
    width: "3.125rem",
    height: "2.75rem",
    viewBox: "0 0 50 44",
    fill: "none",
    xmlns: "http://www.w3.org/2000/svg",
    children: [
      i.jsx("path", {
        d: "M0 22L12.5 1.1059e-06L37.5 0L50 22L37.5 44L12.5 44L0 22Z",
        fill: "#ff4848ff",
        "fill-opacity": "0.1",
      }),
      i.jsx("path", {
        d: "M24.165 16.9994H26.67L29.4172 14.2467C29.4948 14.1686 29.5871 14.1065 29.6889 14.0642C29.7907 14.0218 29.8998 14 30.01 14C30.1203 14 30.2294 14.0218 30.3311 14.0642C30.4329 14.1065 30.5253 14.1686 30.6029 14.2467L32.7572 16.4071C32.9127 16.5634 33 16.7748 33 16.9952C33 17.2156 32.9127 17.427 32.7572 17.5833L30.845 19.5018H24.165V21.17C24.165 21.3913 24.077 21.6034 23.9204 21.7599C23.7638 21.9163 23.5514 22.0042 23.33 22.0042C23.1085 22.0042 22.8961 21.9163 22.7396 21.7599C22.583 21.6034 22.495 21.3913 22.495 21.17V18.6676C22.495 18.2252 22.6709 17.8009 22.9841 17.488C23.2973 17.1751 23.7221 16.9994 24.165 16.9994ZM19.155 21.17V24.5066L17.2428 26.4167C17.0873 26.573 17 26.7844 17 27.0048C17 27.2252 17.0873 27.4366 17.2428 27.5929L19.3971 29.7533C19.4747 29.8314 19.5671 29.8935 19.6689 29.9359C19.7706 29.9782 19.8797 30 19.99 30C20.1002 30 20.2093 29.9782 20.3111 29.9359C20.4129 29.8935 20.5052 29.8314 20.5828 29.7533L24.165 26.1748H27.505C27.7265 26.1748 27.9389 26.087 28.0954 25.9305C28.252 25.7741 28.34 25.5619 28.34 25.3407V24.5066H29.175C29.3965 24.5066 29.6089 24.4187 29.7655 24.2623C29.922 24.1058 30.01 23.8937 30.01 23.6724V22.8383H30.845C31.0665 22.8383 31.2789 22.7504 31.4355 22.594C31.5921 22.4376 31.68 22.2254 31.68 22.0042V21.17H25.835V22.0042C25.835 22.4466 25.6591 22.871 25.3459 23.1838C25.0327 23.4967 24.6079 23.6724 24.165 23.6724H22.495C22.0521 23.6724 21.6273 23.4967 21.3141 23.1838C21.0009 22.871 20.825 22.4466 20.825 22.0042V19.5018L19.155 21.17Z",
        fill: "#ff4848ff",
      }),
    ],
  });
}
function X9({ onClick: r }) {
  return i.jsxs("svg", {
    onClick: r,
    className: "cursor-pointer",
    width: "1.25rem",
    height: "1.25rem",
    viewBox: "0 0 20 20",
    fill: "none",
    xmlns: "http://www.w3.org/2000/svg",
    children: [
      i.jsx("rect", {
        width: "20",
        height: "20",
        rx: "4",
        fill: "#C33C2E",
        "fill-opacity": "0.15",
      }),
      i.jsx("path", {
        fillRule: "evenodd",
        clipRule: "evenodd",
        d: "M10.0046 11.0768L12.6987 13.7679C12.8416 13.9107 13.0355 13.9909 13.2377 13.9909C13.4399 13.9909 13.6338 13.9107 13.7767 13.7679C13.9197 13.6251 14 13.4314 14 13.2295C14 13.0275 13.9197 12.8338 13.7767 12.691L11.0816 10L13.7762 7.30895C13.847 7.23825 13.9031 7.15431 13.9414 7.06195C13.9796 6.96958 13.9993 6.87058 13.9993 6.77062C13.9993 6.67065 13.9796 6.57166 13.9412 6.47931C13.9029 6.38696 13.8468 6.30305 13.776 6.23238C13.7052 6.16171 13.6212 6.10566 13.5287 6.06742C13.4362 6.02919 13.3371 6.00952 13.237 6.00954C13.1369 6.00957 13.0378 6.02928 12.9454 6.06756C12.8529 6.10584 12.7689 6.16193 12.6982 6.23264L10.0046 8.92368L7.31044 6.23264C7.24018 6.1599 7.15611 6.10187 7.06316 6.06194C6.9702 6.022 6.87022 6.00096 6.76903 6.00003C6.66785 5.99911 6.56749 6.01832 6.47382 6.05655C6.38015 6.09478 6.29504 6.15126 6.22345 6.22269C6.15187 6.29413 6.09525 6.37909 6.05688 6.47262C6.01852 6.56615 5.99919 6.66637 6.00003 6.76744C6.00086 6.86851 6.02183 6.9684 6.06173 7.06129C6.10162 7.15417 6.15963 7.23819 6.23238 7.30845L8.92752 10L6.23289 12.6916C6.16014 12.7618 6.10213 12.8458 6.06223 12.9387C6.02234 13.0316 6.00136 13.1315 6.00053 13.2326C5.9997 13.3336 6.01903 13.4339 6.05739 13.5274C6.09575 13.6209 6.15238 13.7059 6.22396 13.7773C6.29555 13.8487 6.38066 13.9052 6.47433 13.9435C6.568 13.9817 6.66836 14.0009 6.76954 14C6.87073 13.999 6.97071 13.978 7.06367 13.9381C7.15662 13.8981 7.24068 13.8401 7.31095 13.7674L10.0046 11.0768Z",
        fill: "#C33C2E",
      }),
    ],
  });
}
function J9({ partner: r, onMarkLocal: s, onDelete: a, canDelete: c }) {
  return i.jsxs("div", {
    className:
      "w-[19.9063rem] h-[10.875rem] rounded-[.3125rem] bg-white/[.02] p-4 flex flex-col justify-between",
    children: [
      i.jsxs("div", {
        className: "w-full flex items-start justify-between",
        children: [
          i.jsxs("div", {
            className: "flex items-center gap-3",
            children: [
              i.jsx(Y9, {}),
              i.jsxs("div", {
                children: [
                  i.jsx("p", {
                    className: "text-white/65 text-xs font-medium",
                    children: "PARCEIRO",
                  }),
                  i.jsx("p", {
                    className: "text-white text-sm font-bold uppercase",
                    children: r.name,
                  }),
                ],
              }),
            ],
          }),
          c && a && i.jsx(X9, { onClick: () => a(r) }),
        ],
      }),
      i.jsx("hr", {
        className:
          "w-full h-[.0625rem] bg-white/5 border-none outline-none flex-none",
      }),
      i.jsx("p", {
        className: "text-white/45 text-xs font-medium truncate",
        children: r.keyword,
      }),
      i.jsxs("button", {
        onClick: () => s(r.cds),
        className:
          "w-full h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 text-[#151716] text-sm font-bold rounded-[.3125rem] flex items-center justify-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".75rem",
            height: ".625rem",
            viewBox: "0 0 12 10",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M11.6067 1.18125L8.94037 0.0562501H8.39377L6.00073 1.0625L3.60769 0.0562501H3.57436L3.49437 0H3.09442L0.428078 1.125C0.295086 1.17278 0.181912 1.25924 0.10514 1.37171C0.028368 1.48419 -0.00796591 1.61676 0.00146288 1.75V9.375C0.00164869 9.47957 0.0298171 9.58243 0.0833878 9.67416C0.136959 9.76588 0.214219 9.84353 0.308092 9.9C0.415381 9.96498 0.540323 9.99969 0.668048 10C0.762367 9.99959 0.855519 9.98042 0.941348 9.94375L3.33439 8.9375L5.72743 9.94375H5.76076C5.83588 9.97668 5.9178 9.99375 6.00073 9.99375C6.08366 9.99375 6.16558 9.97668 6.2407 9.94375H6.27403L8.66707 8.9375L11.0601 9.94375C11.1459 9.98042 11.2391 9.99959 11.3334 10C11.4611 9.99969 11.5861 9.96498 11.6934 9.9C11.7872 9.84353 11.8645 9.76588 11.9181 9.67416C11.9716 9.58243 11.9998 9.47957 12 9.375V1.75C11.9997 1.62977 11.9625 1.51217 11.8927 1.41129C11.823 1.31042 11.7237 1.23054 11.6067 1.18125ZM4.00098 1.59375L5.33415 2.15V8.4L4.00098 7.84375V1.59375ZM10.6668 8.40625L9.33366 7.85V1.6L10.6668 2.15625V8.40625Z",
              fill: "#151716",
            }),
          }),
          "MARCAR NO MAPA",
        ],
      }),
    ],
  });
}
function q9() {
  const [r, s] = p.useState(""),
    { permissions: a, partners: c, setPartners: d } = Ze(),
    m = c.filter((v) =>
      v.name.toLocaleLowerCase().includes(r.toLocaleLowerCase()),
    );
  function x(v) {
    se("MarkLocal", { cds: v }, !0);
  }
  function h(v) {
    se("DeletePartner", { partner: v }, []).then(d);
  }
  return (
    p.useEffect(() => {
      se("GetPartners", {}, [
        {
          cds: "xu; pa; 11;",
          note: 5,
          name: "XP Tecnologia",
          keyword: "financeiro",
          description:
            "Parceiro especialista em soluções de investimento tecnológico e financeiro. Atuação nacional.",
          icon: "https://randomuser.me/api/portraits/men/45.jpg",
        },
        {
          cds: "av; ro; 16;",
          note: 4,
          name: "Real Logística",
          keyword: "transporte",
          description:
            "Atua nos ramos de logística e transporte de cargas pesadas. Mais de 20 anos de experiência.",
          icon: "https://randomuser.me/api/portraits/men/56.jpg",
        },
        {
          cds: "cl; fr; 35;",
          note: 2,
          name: "FarmaVida",
          keyword: "saúde",
          description:
            "Rede de farmácias presente em várias cidades e distritos. Atendimento 24h.",
          icon: "https://randomuser.me/api/portraits/women/65.jpg",
        },
        {
          cds: "pr; op; 52;",
          note: 3,
          name: "ElectroMax",
          keyword: "eletrônicos",
          description:
            "Referência em vendas e assistência técnica em eletrônicos e informática.",
          icon: "https://randomuser.me/api/portraits/men/24.jpg",
        },
        {
          cds: "bv; mn; 48;",
          note: 1,
          name: "Construtora Elite",
          keyword: "construção",
          description:
            "Construção civil e projetos arquitetônicos inovadores, desde 2005 no mercado.",
          icon: "https://randomuser.me/api/portraits/men/78.jpg",
        },
        {
          cds: "na; fa; 77;",
          note: 4,
          name: "Floricultura Pétalas",
          keyword: "flores",
          description:
            "Especializada em arranjos florais exclusivos e entrega rápida em toda região.",
          icon: "https://randomuser.me/api/portraits/women/85.jpg",
        },
        {
          cds: "mn; er; 22;",
          note: 2,
          name: "Pet Center",
          keyword: "animais",
          description:
            "Tudo para pets: alimentos, acessórios, banho e tosa. Amor pelos animais em primeiro lugar.",
          icon: "https://randomuser.me/api/portraits/men/93.jpg",
        },
        {
          cds: "as; tr; 14;",
          note: 3,
          name: "Armazém São João",
          keyword: "mercado",
          description:
            "Supermercado completo e tradicional na cidade, com serviços de entrega.",
          icon: "https://randomuser.me/api/portraits/women/38.jpg",
        },
        {
          cds: "bu; pa; 09;",
          note: 2,
          name: "Buffet Sabor & Arte",
          keyword: "gastronomia",
          description:
            "Buffet especializado em eventos empresariais, aniversários e casamentos.",
          icon: "https://randomuser.me/api/portraits/women/44.jpg",
        },
        {
          cds: "ca; rr; 81;",
          note: 5,
          name: "AutoCar Multimarcas",
          keyword: "automóveis",
          description:
            "Venda de veículos novos e seminovos, financiamento facilitado e garantia premium.",
          icon: "https://randomuser.me/api/portraits/men/88.jpg",
        },
        {
          cds: "so; ma; 37;",
          note: 1,
          name: "Sonho de Festa",
          keyword: "eventos",
          description:
            "Organização e decoração de festas infantis e corporativas, aluguel de brinquedos.",
          icon: "https://randomuser.me/api/portraits/women/67.jpg",
        },
        {
          cds: "dn; ga; 53;",
          note: 4,
          name: "Gás & Água Express",
          keyword: "utilidades",
          description:
            "Entrega rápida de água mineral e gás de cozinha para residências e empresas.",
          icon: "https://randomuser.me/api/portraits/men/11.jpg",
        },
        {
          cds: "st; re; 18;",
          note: 3,
          name: "Studio Fit",
          keyword: "fitness",
          description:
            "Academia de musculação, pilates, funcional, personal trainers experientes.",
          icon: "https://randomuser.me/api/portraits/women/59.jpg",
        },
        {
          cds: "ba; dr; 95;",
          note: 5,
          name: "Barbearia Barbudo",
          keyword: "beleza",
          description:
            "Corte de cabelo, barba e tratamentos masculinos em ambiente descontraído.",
          icon: "https://randomuser.me/api/portraits/men/62.jpg",
        },
        {
          cds: "fr; sk; 61;",
          note: 2,
          name: "Frescor Açaí",
          keyword: "alimentação",
          description:
            "Açaí, smoothies, sucos naturais e lanches saudáveis, ambiente jovem e moderno.",
          icon: "https://randomuser.me/api/portraits/women/81.jpg",
        },
      ]).then(d);
    }, []),
    i.jsxs("div", {
      className:
        "size-full bg-white/[.01] border-[.0625rem] border-white/5 rounded-[.3125rem] p-4 flex flex-col gap-3",
      children: [
        i.jsx(K9, { search: r, setSearch: s, partnersCount: c.length }),
        i.jsx("div", {
          className: "w-[101%] flex-1 flex flex-wrap gap-3 overflow-y-auto",
          children: m.map((v) =>
            i.jsx(
              J9,
              { partner: v, onMarkLocal: x, onDelete: h, canDelete: a.leader },
              v.name,
            ),
          ),
        }),
      ],
    })
  );
}
function Oa({
  type: r,
  orgBalance: s,
  playerBalance: a,
  canWithdraw: c,
  canDeposit: d,
}) {
  const [m, x] = p.useState(!1),
    h = p.useRef(null),
    v = () => {
      var y, M;
      (y = h.current) != null &&
        y.value &&
        se(
          r === "withdraw" ? "Withdraw" : "Deposit",
          { value: Number((M = h.current) == null ? void 0 : M.value) },
          !0,
        ).then((j) => {
          j && x(!1);
        });
    };
  return i.jsxs(jt, {
    open: m,
    onOpenChange: x,
    children: [
      i.jsx(Nt, {
        asChild: !0,
        children:
          r === "withdraw"
            ? i.jsxs("button", {
                disabled: !c,
                className:
                  "w-[10rem] h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 flex items-center justify-center gap-2 rounded-[.3125rem] disabled:opacity-50 disabled:cursor-not-allowed",
                children: [
                  i.jsxs("svg", {
                    width: "1.25rem",
                    height: ".625rem",
                    viewBox: "0 0 20 10",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: [
                      i.jsx("path", {
                        fillRule: "evenodd",
                        clipRule: "evenodd",
                        d: "M12.4998 0H14.9998C17.3567 0 18.5355 0 19.2673 0.7325C19.7948 1.25937 19.9423 2.01813 19.9836 3.28125H7.51609C7.55734 2.01813 7.70484 1.25937 8.23234 0.7325C8.96422 0 10.143 0 12.4998 0ZM14.9998 10H12.4998C10.143 10 8.96422 10 8.23234 9.2675C7.50047 8.535 7.49984 7.35687 7.49984 5C7.49984 4.72417 7.50026 4.46375 7.50109 4.21875H19.9986C19.9998 4.46375 20.0003 4.72417 19.9998 5C19.9998 7.35687 19.9998 8.53562 19.2673 9.2675C18.5348 9.99937 17.3567 10 14.9998 10ZM13.7688 7.16854C13.8567 7.25645 13.9061 7.37568 13.9061 7.5C13.9061 7.62432 13.8567 7.74355 13.7688 7.83146C13.6809 7.91936 13.5617 7.96875 13.4373 7.96875H12.4998C12.3755 7.96875 12.2563 7.91936 12.1684 7.83146C12.0805 7.74355 12.0311 7.62432 12.0311 7.5C12.0311 7.37568 12.0805 7.25645 12.1684 7.16854C12.2563 7.08064 12.3755 7.03125 12.4998 7.03125H13.4373C13.5617 7.03125 13.6809 7.08064 13.7688 7.16854ZM17.8313 7.16854C17.9192 7.25645 17.9686 7.37568 17.9686 7.5C17.9686 7.62432 17.9192 7.74355 17.8313 7.83146C17.7434 7.91936 17.6242 7.96875 17.4998 7.96875H14.9998C14.8755 7.96875 14.7563 7.91936 14.6684 7.83146C14.5805 7.74355 14.5311 7.62432 14.5311 7.5C14.5311 7.37568 14.5805 7.25645 14.6684 7.16854C14.7563 7.08064 14.8755 7.03125 14.9998 7.03125H17.4998C17.6242 7.03125 17.7434 7.08064 17.8313 7.16854Z",
                        fill: "#151716",
                      }),
                      i.jsx("path", {
                        d: "M2.3112 6.85195C2.19662 6.89649 2.0638 6.87539 1.97266 6.79803L0.0976562 5.20395C0.0351562 5.1512 0 5.07736 0 5C0 4.92264 0.0351562 4.8488 0.0976562 4.79605L1.97266 3.20197C2.0638 3.12461 2.19661 3.10351 2.3112 3.14805C2.42578 3.19259 2.5 3.29339 2.5 3.40591V4.24984H4.58333C4.8138 4.24984 5 4.41746 5 4.62492V5.37508C5 5.58254 4.8138 5.75016 4.58333 5.75016H2.5V6.59409C2.5 6.70661 2.42578 6.80741 2.3112 6.85195Z",
                        fill: "#151716",
                      }),
                    ],
                  }),
                  "SACAR",
                ],
              })
            : i.jsxs("button", {
                disabled: !d,
                className:
                  "w-[10rem] h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 flex items-center justify-center gap-2 rounded-[.3125rem] disabled:opacity-50 disabled:cursor-not-allowed",
                children: [
                  i.jsxs("svg", {
                    width: "1.25rem",
                    height: ".625rem",
                    viewBox: "0 0 20 10",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: [
                      i.jsx("path", {
                        fillRule: "evenodd",
                        clipRule: "evenodd",
                        d: "M7.50016 0H5.00016C2.64328 0 1.46453 0 0.732656 0.7325C0.205156 1.25937 0.0576563 2.01813 0.0164063 3.28125H12.4839C12.4427 2.01813 12.2952 1.25937 11.7677 0.7325C11.0358 0 9.85703 0 7.50016 0ZM5.00016 10H7.50016C9.85703 10 11.0358 10 11.7677 9.2675C12.4995 8.535 12.5002 7.35687 12.5002 5C12.5002 4.72417 12.4997 4.46375 12.4989 4.21875H0.0014063C0.000156299 4.46375 -0.000260426 4.72417 0.000156241 5C0.000156241 7.35687 0.000156164 8.53562 0.732656 9.2675C1.46516 9.99937 2.64328 10 5.00016 10ZM6.2312 7.16854C6.14329 7.25645 6.09391 7.37568 6.09391 7.5C6.09391 7.62432 6.14329 7.74355 6.2312 7.83146C6.31911 7.91936 6.43834 7.96875 6.56266 7.96875H7.50016C7.62448 7.96875 7.7437 7.91936 7.83161 7.83146C7.91952 7.74355 7.96891 7.62432 7.96891 7.5C7.96891 7.37568 7.91952 7.25645 7.83161 7.16854C7.7437 7.08064 7.62448 7.03125 7.50016 7.03125H6.56266C6.43834 7.03125 6.31911 7.08064 6.2312 7.16854ZM2.1687 7.16854C2.08079 7.25645 2.03141 7.37568 2.03141 7.5C2.03141 7.62432 2.08079 7.74355 2.1687 7.83146C2.25661 7.91936 2.37584 7.96875 2.50016 7.96875H5.00016C5.12448 7.96875 5.2437 7.91936 5.33161 7.83146C5.41952 7.74355 5.46891 7.62432 5.46891 7.5C5.46891 7.37568 5.41952 7.25645 5.33161 7.16854C5.2437 7.08064 5.12448 7.03125 5.00016 7.03125H2.50016C2.37584 7.03125 2.25661 7.08064 2.1687 7.16854Z",
                        fill: "#151716",
                      }),
                      i.jsx("path", {
                        d: "M17.6888 6.85195C17.8034 6.89649 17.9362 6.87539 18.0273 6.79803L19.9023 5.20395C19.9648 5.1512 20 5.07736 20 5C20 4.92264 19.9648 4.8488 19.9023 4.79605L18.0273 3.20197C17.9362 3.12461 17.8034 3.10351 17.6888 3.14805C17.5742 3.19259 17.5 3.29339 17.5 3.40591V4.24984H15.4167C15.1862 4.24984 15 4.41746 15 4.62492V5.37508C15 5.58254 15.1862 5.75016 15.4167 5.75016H17.5V6.59409C17.5 6.70661 17.5742 6.80741 17.6888 6.85195Z",
                        fill: "#151716",
                      }),
                    ],
                  }),
                  "DEPÓSITO",
                ],
              }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[22rem] p-4 rounded-[.5625rem] flex flex-col gap-4 border-[.0563rem] border-white/10 bg-[#151716]",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2 w-full",
                children: [
                  r === "withdraw"
                    ? i.jsxs("svg", {
                        width: "1.25rem",
                        height: ".625rem",
                        viewBox: "0 0 20 10",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          i.jsx("path", {
                            "fill-rule": "evenodd",
                            "clip-rule": "evenodd",
                            d: "M12.4998 0H14.9998C17.3567 0 18.5355 0 19.2673 0.7325C19.7948 1.25937 19.9423 2.01813 19.9836 3.28125H7.51609C7.55734 2.01813 7.70484 1.25937 8.23234 0.7325C8.96422 0 10.143 0 12.4998 0ZM14.9998 10H12.4998C10.143 10 8.96422 10 8.23234 9.2675C7.50047 8.535 7.49984 7.35687 7.49984 5C7.49984 4.72417 7.50026 4.46375 7.50109 4.21875H19.9986C19.9998 4.46375 20.0003 4.72417 19.9998 5C19.9998 7.35687 19.9998 8.53562 19.2673 9.2675C18.5348 9.99937 17.3567 10 14.9998 10ZM13.7688 7.16854C13.8567 7.25645 13.9061 7.37568 13.9061 7.5C13.9061 7.62432 13.8567 7.74355 13.7688 7.83146C13.6809 7.91936 13.5617 7.96875 13.4373 7.96875H12.4998C12.3755 7.96875 12.2563 7.91936 12.1684 7.83146C12.0805 7.74355 12.0311 7.62432 12.0311 7.5C12.0311 7.37568 12.0805 7.25645 12.1684 7.16854C12.2563 7.08064 12.3755 7.03125 12.4998 7.03125H13.4373C13.5617 7.03125 13.6809 7.08064 13.7688 7.16854ZM17.8313 7.16854C17.9192 7.25645 17.9686 7.37568 17.9686 7.5C17.9686 7.62432 17.9192 7.74355 17.8313 7.83146C17.7434 7.91936 17.6242 7.96875 17.4998 7.96875H14.9998C14.8755 7.96875 14.7563 7.91936 14.6684 7.83146C14.5805 7.74355 14.5311 7.62432 14.5311 7.5C14.5311 7.37568 14.5805 7.25645 14.6684 7.16854C14.7563 7.08064 14.8755 7.03125 14.9998 7.03125H17.4998C17.6242 7.03125 17.7434 7.08064 17.8313 7.16854Z",
                            fill: "white",
                            "fill-opacity": "0.25",
                          }),
                          i.jsx("path", {
                            d: "M2.3112 6.85195C2.19662 6.89649 2.0638 6.87539 1.97266 6.79803L0.0976562 5.20395C0.0351562 5.1512 0 5.07736 0 5C0 4.92264 0.0351562 4.8488 0.0976562 4.79605L1.97266 3.20197C2.0638 3.12461 2.19661 3.10351 2.3112 3.14805C2.42578 3.19259 2.5 3.29339 2.5 3.40591V4.24984H4.58333C4.8138 4.24984 5 4.41746 5 4.62492V5.37508C5 5.58254 4.8138 5.75016 4.58333 5.75016H2.5V6.59409C2.5 6.70661 2.42578 6.80741 2.3112 6.85195Z",
                            fill: "white",
                            "fill-opacity": "0.25",
                          }),
                        ],
                      })
                    : i.jsxs("svg", {
                        width: "1.25rem",
                        height: ".625rem",
                        viewBox: "0 0 20 10",
                        fill: "none",
                        xmlns: "http://www.w3.org/2000/svg",
                        children: [
                          i.jsx("path", {
                            "fill-rule": "evenodd",
                            "clip-rule": "evenodd",
                            d: "M7.50016 0H5.00016C2.64328 0 1.46453 0 0.732656 0.7325C0.205156 1.25937 0.0576563 2.01813 0.0164063 3.28125H12.4839C12.4427 2.01813 12.2952 1.25937 11.7677 0.7325C11.0358 0 9.85703 0 7.50016 0ZM5.00016 10H7.50016C9.85703 10 11.0358 10 11.7677 9.2675C12.4995 8.535 12.5002 7.35687 12.5002 5C12.5002 4.72417 12.4997 4.46375 12.4989 4.21875H0.0014063C0.000156299 4.46375 -0.000260426 4.72417 0.000156241 5C0.000156241 7.35687 0.000156164 8.53562 0.732656 9.2675C1.46516 9.99937 2.64328 10 5.00016 10ZM6.2312 7.16854C6.14329 7.25645 6.09391 7.37568 6.09391 7.5C6.09391 7.62432 6.14329 7.74355 6.2312 7.83146C6.31911 7.91936 6.43834 7.96875 6.56266 7.96875H7.50016C7.62448 7.96875 7.7437 7.91936 7.83161 7.83146C7.91952 7.74355 7.96891 7.62432 7.96891 7.5C7.96891 7.37568 7.91952 7.25645 7.83161 7.16854C7.7437 7.08064 7.62448 7.03125 7.50016 7.03125H6.56266C6.43834 7.03125 6.31911 7.08064 6.2312 7.16854ZM2.1687 7.16854C2.08079 7.25645 2.03141 7.37568 2.03141 7.5C2.03141 7.62432 2.08079 7.74355 2.1687 7.83146C2.25661 7.91936 2.37584 7.96875 2.50016 7.96875H5.00016C5.12448 7.96875 5.2437 7.91936 5.33161 7.83146C5.41952 7.74355 5.46891 7.62432 5.46891 7.5C5.46891 7.37568 5.41952 7.25645 5.33161 7.16854C5.2437 7.08064 5.12448 7.03125 5.00016 7.03125H2.50016C2.37584 7.03125 2.25661 7.08064 2.1687 7.16854Z",
                            fill: "white",
                            "fill-opacity": "0.25",
                          }),
                          i.jsx("path", {
                            d: "M17.6888 6.85195C17.8034 6.89649 17.9362 6.87539 18.0273 6.79803L19.9023 5.20395C19.9648 5.1512 20 5.07736 20 5C20 4.92264 19.9648 4.8488 19.9023 4.79605L18.0273 3.20197C17.9362 3.12461 17.8034 3.10351 17.6888 3.14805C17.5742 3.19259 17.5 3.29339 17.5 3.40591V4.24984H15.4167C15.1862 4.24984 15 4.41746 15 4.62492V5.37508C15 5.58254 15.1862 5.75016 15.4167 5.75016H17.5V6.59409C17.5 6.70661 17.5742 6.80741 17.6888 6.85195Z",
                            fill: "white",
                            "fill-opacity": "0.25",
                          }),
                        ],
                      }),
                  i.jsx("h2", {
                    className: "text-white/65 text-sm font-bold",
                    children: r === "withdraw" ? "SACAR" : "DEPOSITAR",
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "VALOR",
                  }),
                  i.jsxs("div", {
                    className:
                      "w-full h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 flex items-center gap-2 rounded-[.3125rem]",
                    children: [
                      i.jsx("p", {
                        className: "text-white/25 text-xs font-medium",
                        children: "R$",
                      }),
                      i.jsx("input", {
                        ref: h,
                        type: "number",
                        className:
                          "flex-1 bg-transparent outline-none text-white/45 text-xs font-medium placeholder:text-white/45",
                      }),
                    ],
                  }),
                  i.jsxs("p", {
                    className:
                      "text-white/45 text-[.625rem] font-normal self-end",
                    children: [
                      "SALDO DISPONÍVEL:",
                      " ",
                      i.jsxs("b", {
                        className: "text-white/60 font-normal",
                        children: [
                          "R$",
                          (r === "withdraw" ? s : a).toLocaleString("pt-BR"),
                        ],
                      }),
                    ],
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx("button", {
                    onClick: v,
                    className:
                      "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                    children: r === "withdraw" ? "SACAR" : "DEPOSITAR",
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function e8({
  orgBalance: r,
  playerBalance: s,
  canDeposit: a,
  canWithdraw: c,
}) {
  return i.jsxs("div", {
    className:
      "w-full h-[11.25rem] border-[.0625rem] border-white/5 bg-white/[.01] flex flex-col gap-3 rounded-[.3125rem] p-4",
    children: [
      i.jsxs("div", {
        className: "w-full flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".5625rem",
            height: ".625rem",
            viewBox: "0 0 9 10",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M4.5 0L0 2.38095V3.33333H9V2.38095M6.63158 4.28571V7.61905H8.05263V4.28571M0 10H9V8.57143H0M3.78947 4.28571V7.61905H5.21053V4.28571M0.947368 4.28571V7.61905H2.36842V4.28571H0.947368Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
          i.jsx("h2", {
            className: "text-white text-xs font-bold",
            children: "BANCO",
          }),
        ],
      }),
      i.jsxs("div", {
        className:
          "w-full flex-1 border-[.0625rem] border-[#ff4848ff] rounded-[.3125rem] flex items-center justify-between px-8",
        style: {
          background:
            "linear-gradient(89.58deg, rgba(255, 72, 72, 0.13) 0%, rgba(255, 72, 72, 0.25) 100%)",
        },
        children: [
          i.jsxs("div", {
            children: [
              i.jsx("p", {
                className: "text-[#ff4848ff] text-base font-medium",
                children: "SALDO NO CAIXA",
              }),
              i.jsxs("p", {
                className: "text-white text-[2rem] font-extrabold",
                children: ["R$", Number(r).toLocaleString("pt-BR")],
              }),
            ],
          }),
          i.jsxs("div", {
            className: "flex flex-col gap-2",
            children: [
              i.jsx(Oa, {
                canWithdraw: c,
                type: "withdraw",
                orgBalance: r,
                playerBalance: s,
              }),
              i.jsx(Oa, {
                canDeposit: a,
                type: "deposit",
                orgBalance: r,
                playerBalance: s,
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function t8({ search: r, onSearchChange: s }) {
  return i.jsxs("div", {
    className: "w-full flex items-center justify-between",
    children: [
      i.jsxs("div", {
        className: "w-full flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".625rem",
            height: ".625rem",
            viewBox: "0 0 10 10",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M7.50009 0.669946C8.25423 1.10537 8.88158 1.73021 9.32002 2.4826C9.75847 3.23498 9.9928 4.08883 9.99984 4.95962C10.0069 5.8304 9.78636 6.68792 9.36013 7.44729C8.93389 8.20667 8.31672 8.84155 7.56971 9.2891C6.8227 9.73666 5.97176 9.98136 5.10111 9.99898C4.23047 10.0166 3.37032 9.80653 2.60581 9.38957C1.8413 8.9726 1.19895 8.36321 0.742342 7.6217C0.285735 6.8802 0.030705 6.0323 0.00250009 5.16195L0 4.99995L0.00250009 4.83794C0.030502 3.97444 0.281777 3.13293 0.731829 2.39544C1.18188 1.65796 1.81535 1.04967 2.57048 0.629887C3.32561 0.210103 4.17662 -0.00685539 5.04057 0.000165123C5.90451 0.00718564 6.75189 0.237945 7.50009 0.669946ZM5.00006 1.99995C4.87759 1.99996 4.75939 2.04492 4.66787 2.1263C4.57635 2.20768 4.51788 2.31982 4.50356 2.44145L4.50006 2.49995V4.99995L4.50456 5.06544C4.51596 5.15219 4.54992 5.23443 4.60306 5.30395L4.64656 5.35395L6.14658 6.85394L6.19358 6.89494C6.28126 6.96298 6.38909 6.9999 6.50008 6.9999C6.61106 6.9999 6.7189 6.96298 6.80658 6.89494L6.85358 6.85344L6.89508 6.80644C6.96312 6.71876 7.00004 6.61093 7.00004 6.49995C7.00004 6.38896 6.96312 6.28113 6.89508 6.19345L6.85358 6.14645L5.50007 4.79245V2.49995L5.49657 2.44145C5.48224 2.31982 5.42377 2.20768 5.33225 2.1263C5.24073 2.04492 5.12253 1.99996 5.00006 1.99995Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
          i.jsx("h2", {
            className: "text-white text-xs font-bold",
            children: "HISTÓRICO",
          }),
        ],
      }),
      i.jsxs("div", {
        className:
          "w-[15rem] h-8 bg-white/[.02] border-[.0625rem] border-white/5 rounded-[.3125rem] px-4 flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".75rem",
            height: ".75rem",
            viewBox: "0 0 12 12",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M9.46992 8.63464L12 11.1641L11.1641 12L8.63464 9.46992C7.69346 10.2244 6.52279 10.6348 5.31653 10.6331C2.38181 10.6331 0 8.25126 0 5.31653C0 2.38181 2.38181 0 5.31653 0C8.25126 0 10.6331 2.38181 10.6331 5.31653C10.6348 6.52279 10.2244 7.69346 9.46992 8.63464ZM8.28493 8.19632C9.03446 7.42525 9.45312 6.39187 9.45161 5.31653C9.45161 3.03219 7.60087 1.18145 5.31653 1.18145C3.03219 1.18145 1.18145 3.03219 1.18145 5.31653C1.18145 7.60087 3.03219 9.45161 5.31653 9.45161C6.39187 9.45312 7.42525 9.03446 8.19632 8.28493L8.28493 8.19632Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
          i.jsx("input", {
            type: "text",
            name: "search",
            id: "search",
            value: r,
            onChange: (a) => s(a.target.value),
            placeholder: "PESQUISAR...",
            className:
              "text-white/45 text-xs font-semibold placeholder:text-white/45 flex-1 bg-transparent outline-none border-none",
          }),
        ],
      }),
    ],
  });
}
function n8({ sortStyle: r, sortOrder: s, onToggleSort: a }) {
  return i.jsxs("div", {
    className: "w-full h-8 bg-white/[.02] flex items-center px-4",
    children: [
      i.jsxs("button", {
        onClick: () => a("id"),
        className: "flex items-center gap-1.5 w-[8rem] cursor-pointer",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold",
              r === "id" ? "text-white" : "text-white/60",
            ),
            children: "ID",
          }),
          i.jsx("svg", {
            width: ".5625rem",
            height: ".3125rem",
            viewBox: "0 0 9 5",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            className: ne(r === "id" && s === "desc" && "rotate-180"),
            children: i.jsx("path", {
              fillRule: "evenodd",
              clipRule: "evenodd",
              d: "M4.9788 4.8085C4.8518 4.93112 4.67958 5 4.5 5C4.32042 5 4.1482 4.93112 4.0212 4.8085L0.190107 1.10845C0.0667439 0.985094 -0.0015173 0.819876 2.57492e-05 0.648382C0.00156879 0.476888 0.072793 0.31284 0.198358 0.191571C0.323921 0.0703025 0.493779 0.00151491 0.671347 2.47955e-05C0.848914 -0.00146532 1.01998 0.0644608 1.14771 0.183604L4.5 3.42123L7.85229 0.183604C7.98002 0.0644608 8.15109 -0.00146532 8.32865 2.47955e-05C8.50622 0.00151491 8.67608 0.0703025 8.80164 0.191571C8.92721 0.31284 8.99843 0.476888 8.99997 0.648382C9.00152 0.819876 8.93326 0.985094 8.80989 1.10845L4.9788 4.8085Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
        ],
      }),
      i.jsxs("button", {
        onClick: () => a("name"),
        className: "flex items-center gap-1.5 w-[17.9688rem] cursor-pointer",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold",
              r === "name" ? "text-white" : "text-white/60",
            ),
            children: "NOME",
          }),
          i.jsx("svg", {
            width: ".5625rem",
            height: ".3125rem",
            viewBox: "0 0 9 5",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            className: ne(r === "name" && s === "desc" && "rotate-180"),
            children: i.jsx("path", {
              fillRule: "evenodd",
              clipRule: "evenodd",
              d: "M4.9788 4.8085C4.8518 4.93112 4.67958 5 4.5 5C4.32042 5 4.1482 4.93112 4.0212 4.8085L0.190107 1.10845C0.0667439 0.985094 -0.0015173 0.819876 2.57492e-05 0.648382C0.00156879 0.476888 0.072793 0.31284 0.198358 0.191571C0.323921 0.0703025 0.493779 0.00151491 0.671347 2.47955e-05C0.848914 -0.00146532 1.01998 0.0644608 1.14771 0.183604L4.5 3.42123L7.85229 0.183604C7.98002 0.0644608 8.15109 -0.00146532 8.32865 2.47955e-05C8.50622 0.00151491 8.67608 0.0703025 8.80164 0.191571C8.92721 0.31284 8.99843 0.476888 8.99997 0.648382C9.00152 0.819876 8.93326 0.985094 8.80989 1.10845L4.9788 4.8085Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
        ],
      }),
      i.jsxs("button", {
        onClick: () => a("type"),
        className: "flex items-center gap-1.5 w-[17.9688rem] cursor-pointer",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold",
              r === "type" ? "text-white" : "text-white/60",
            ),
            children: "TIPO",
          }),
          i.jsx("svg", {
            width: ".5625rem",
            height: ".3125rem",
            viewBox: "0 0 9 5",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            className: ne(r === "type" && s === "desc" && "rotate-180"),
            children: i.jsx("path", {
              fillRule: "evenodd",
              clipRule: "evenodd",
              d: "M4.9788 4.8085C4.8518 4.93112 4.67958 5 4.5 5C4.32042 5 4.1482 4.93112 4.0212 4.8085L0.190107 1.10845C0.0667439 0.985094 -0.0015173 0.819876 2.57492e-05 0.648382C0.00156879 0.476888 0.072793 0.31284 0.198358 0.191571C0.323921 0.0703025 0.493779 0.00151491 0.671347 2.47955e-05C0.848914 -0.00146532 1.01998 0.0644608 1.14771 0.183604L4.5 3.42123L7.85229 0.183604C7.98002 0.0644608 8.15109 -0.00146532 8.32865 2.47955e-05C8.50622 0.00151491 8.67608 0.0703025 8.80164 0.191571C8.92721 0.31284 8.99843 0.476888 8.99997 0.648382C9.00152 0.819876 8.93326 0.985094 8.80989 1.10845L4.9788 4.8085Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
        ],
      }),
      i.jsxs("button", {
        onClick: () => a("value"),
        className: "flex items-center gap-1.5 w-[17.9688rem] cursor-pointer",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold",
              r === "value" ? "text-white" : "text-white/60",
            ),
            children: "VALOR",
          }),
          i.jsx("svg", {
            width: ".5625rem",
            height: ".3125rem",
            viewBox: "0 0 9 5",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            className: ne(r === "value" && s === "desc" && "rotate-180"),
            children: i.jsx("path", {
              fillRule: "evenodd",
              clipRule: "evenodd",
              d: "M4.9788 4.8085C4.8518 4.93112 4.67958 5 4.5 5C4.32042 5 4.1482 4.93112 4.0212 4.8085L0.190107 1.10845C0.0667439 0.985094 -0.0015173 0.819876 2.57492e-05 0.648382C0.00156879 0.476888 0.072793 0.31284 0.198358 0.191571C0.323921 0.0703025 0.493779 0.00151491 0.671347 2.47955e-05C0.848914 -0.00146532 1.01998 0.0644608 1.14771 0.183604L4.5 3.42123L7.85229 0.183604C7.98002 0.0644608 8.15109 -0.00146532 8.32865 2.47955e-05C8.50622 0.00151491 8.67608 0.0703025 8.80164 0.191571C8.92721 0.31284 8.99843 0.476888 8.99997 0.648382C9.00152 0.819876 8.93326 0.985094 8.80989 1.10845L4.9788 4.8085Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
        ],
      }),
      i.jsxs("button", {
        onClick: () => a("date"),
        className:
          "flex items-center justify-center gap-1.5 w-[17.9688rem] cursor-pointer",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold",
              r === "date" ? "text-white" : "text-white/60",
            ),
            children: "DATA",
          }),
          i.jsx("svg", {
            width: ".5625rem",
            height: ".3125rem",
            viewBox: "0 0 9 5",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            className: ne(r === "date" && s === "desc" && "rotate-180"),
            children: i.jsx("path", {
              fillRule: "evenodd",
              clipRule: "evenodd",
              d: "M4.9788 4.8085C4.8518 4.93112 4.67958 5 4.5 5C4.32042 5 4.1482 4.93112 4.0212 4.8085L0.190107 1.10845C0.0667439 0.985094 -0.0015173 0.819876 2.57492e-05 0.648382C0.00156879 0.476888 0.072793 0.31284 0.198358 0.191571C0.323921 0.0703025 0.493779 0.00151491 0.671347 2.47955e-05C0.848914 -0.00146532 1.01998 0.0644608 1.14771 0.183604L4.5 3.42123L7.85229 0.183604C7.98002 0.0644608 8.15109 -0.00146532 8.32865 2.47955e-05C8.50622 0.00151491 8.67608 0.0703025 8.80164 0.191571C8.92721 0.31284 8.99843 0.476888 8.99997 0.648382C9.00152 0.819876 8.93326 0.985094 8.80989 1.10845L4.9788 4.8085Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
        ],
      }),
    ],
  });
}
function r8({ extract: r }) {
  return i.jsxs("div", {
    className:
      "w-full flex items-center px-4 h-10 bg-white/[.04] rounded-[.3125rem] flex-none",
    children: [
      i.jsx("p", {
        className: "text-white text-xs font-medium w-[8rem] uppercase",
        children: r.id,
      }),
      i.jsx("p", {
        className: "text-white text-xs font-medium w-[17.9688rem] uppercase",
        children: r.name,
      }),
      i.jsx("div", {
        className: "w-[17.9688rem] flex items-center",
        children: i.jsxs("div", {
          className: ne(
            "w-max h-[1.375rem] rounded-[.3125rem] flex items-center justify-center gap-1.5 px-2",
            r.type === "withdraw" && "bg-[#C33C2E]/[.08]",
            r.type === "deposit" && "bg-[#67C32E]/[.08]",
          ),
          children: [
            r.type === "withdraw"
              ? i.jsxs("svg", {
                  width: "1.5rem",
                  height: ".75rem",
                  viewBox: "0 0 24 12",
                  fill: "none",
                  xmlns: "http://www.w3.org/2000/svg",
                  children: [
                    i.jsx("path", {
                      fillRule: "evenodd",
                      clipRule: "evenodd",
                      d: "M14.9998 0H17.9998C20.8281 0 22.2426 0 23.1208 0.879C23.7538 1.51125 23.9308 2.42175 23.9803 3.9375H9.01931C9.06881 2.42175 9.24581 1.51125 9.87881 0.879C10.7571 0 12.1716 0 14.9998 0ZM17.9998 12H14.9998C12.1716 12 10.7571 12 9.87881 11.121C9.00056 10.242 8.99981 8.82825 8.99981 6C8.99981 5.669 9.00031 5.3565 9.00131 5.0625H23.9983C23.9998 5.3565 24.0003 5.669 23.9998 6C23.9998 8.82825 23.9998 10.2428 23.1208 11.121C22.2418 11.9992 20.8281 12 17.9998 12ZM16.5226 8.60225C16.628 8.70774 16.6873 8.85082 16.6873 9C16.6873 9.14918 16.628 9.29226 16.5226 9.39775C16.4171 9.50324 16.274 9.5625 16.1248 9.5625H14.9998C14.8506 9.5625 14.7076 9.50324 14.6021 9.39775C14.4966 9.29226 14.4373 9.14918 14.4373 9C14.4373 8.85082 14.4966 8.70774 14.6021 8.60225C14.7076 8.49676 14.8506 8.4375 14.9998 8.4375H16.1248C16.274 8.4375 16.4171 8.49676 16.5226 8.60225ZM21.3976 8.60225C21.503 8.70774 21.5623 8.85082 21.5623 9C21.5623 9.14918 21.503 9.29226 21.3976 9.39775C21.2921 9.50324 21.149 9.5625 20.9998 9.5625H17.9998C17.8506 9.5625 17.7076 9.50324 17.6021 9.39775C17.4966 9.29226 17.4373 9.14918 17.4373 9C17.4373 8.85082 17.4966 8.70774 17.6021 8.60225C17.7076 8.49676 17.8506 8.4375 17.9998 8.4375H20.9998C21.149 8.4375 21.2921 8.49676 21.3976 8.60225Z",
                      fill: "#C33C2E",
                    }),
                    i.jsx("path", {
                      d: "M2.77344 8.22234C2.63594 8.27579 2.47656 8.25047 2.36719 8.15764L0.117188 6.24474C0.0421867 6.18144 0 6.09283 0 6C0 5.90717 0.0421867 5.81856 0.117188 5.75526L2.36719 3.84236C2.47656 3.74953 2.63594 3.72421 2.77344 3.77766C2.91094 3.83111 3 3.95207 3 4.0871V5.09981H5.5C5.77656 5.09981 6 5.30095 6 5.54991V6.45009C6 6.69905 5.77656 6.90019 5.5 6.90019H3V7.9129C3 8.04793 2.91094 8.16889 2.77344 8.22234Z",
                      fill: "#C33C2E",
                    }),
                  ],
                })
              : i.jsxs("svg", {
                  width: "1.5rem",
                  height: ".75rem",
                  viewBox: "0 0 24 12",
                  fill: "none",
                  xmlns: "http://www.w3.org/2000/svg",
                  children: [
                    i.jsx("path", {
                      fillRule: "evenodd",
                      clipRule: "evenodd",
                      d: "M9.00019 0H6.00019C3.17194 0 1.75744 0 0.879187 0.879C0.246187 1.51125 0.0691875 2.42175 0.0196875 3.9375H14.9807C14.9312 2.42175 14.7542 1.51125 14.1212 0.879C13.2429 0 11.8284 0 9.00019 0ZM6.00019 12H9.00019C11.8284 12 13.2429 12 14.1212 11.121C14.9994 10.242 15.0002 8.82825 15.0002 6C15.0002 5.669 14.9997 5.3565 14.9987 5.0625H0.00168756C0.000187559 5.3565 -0.000312511 5.669 0.000187489 6C0.000187489 8.82825 0.000187397 10.2428 0.879187 11.121C1.75819 11.9992 3.17194 12 6.00019 12ZM7.47744 8.60225C7.37195 8.70774 7.31269 8.85082 7.31269 9C7.31269 9.14918 7.37195 9.29226 7.47744 9.39775C7.58293 9.50324 7.726 9.5625 7.87519 9.5625H9.00019C9.14937 9.5625 9.29245 9.50324 9.39793 9.39775C9.50342 9.29226 9.56269 9.14918 9.56269 9C9.56269 8.85082 9.50342 8.70774 9.39793 8.60225C9.29245 8.49676 9.14937 8.4375 9.00019 8.4375H7.87519C7.726 8.4375 7.58293 8.49676 7.47744 8.60225ZM2.60244 8.60225C2.49695 8.70774 2.43769 8.85082 2.43769 9C2.43769 9.14918 2.49695 9.29226 2.60244 9.39775C2.70793 9.50324 2.851 9.5625 3.00019 9.5625H6.00019C6.14937 9.5625 6.29245 9.50324 6.39793 9.39775C6.50342 9.29226 6.56269 9.14918 6.56269 9C6.56269 8.85082 6.50342 8.70774 6.39793 8.60225C6.29245 8.49676 6.14937 8.4375 6.00019 8.4375H3.00019C2.851 8.4375 2.70793 8.49676 2.60244 8.60225Z",
                      fill: "#67C32E",
                    }),
                    i.jsx("path", {
                      d: "M21.2266 8.22234C21.3641 8.27579 21.5234 8.25047 21.6328 8.15764L23.8828 6.24474C23.9578 6.18144 24 6.09283 24 6C24 5.90717 23.9578 5.81856 23.8828 5.75526L21.6328 3.84236C21.5234 3.74953 21.3641 3.72421 21.2266 3.77766C21.0891 3.83111 21 3.95207 21 4.0871V5.09981H18.5C18.2234 5.09981 18 5.30095 18 5.54991V6.45009C18 6.69905 18.2234 6.90019 18.5 6.90019H21V7.9129C21 8.04793 21.0891 8.16889 21.2266 8.22234Z",
                      fill: "#67C32E",
                    }),
                  ],
                }),
            i.jsx("p", {
              className: ne(
                "text-xs font-semibold",
                r.type === "withdraw" && "text-[#C33C2E]",
                r.type === "deposit" && "text-[#67C32E]",
              ),
              children: r.type === "withdraw" ? "SAQUE" : "DEPÓSITO",
            }),
          ],
        }),
      }),
      i.jsxs("p", {
        className: "text-white text-xs font-medium w-[17.9688rem] uppercase",
        children: ["R$", Number(r.value).toLocaleString("pt-BR")],
      }),
      i.jsx("p", {
        className:
          "text-white/65 text-xs font-medium w-[17.9688rem] text-center uppercase",
        children: r.date,
      }),
    ],
  });
}
function l8() {
  const [r, s] = p.useState([]),
    [a, c] = p.useState(""),
    [d, m] = p.useState("id"),
    [x, h] = p.useState("asc"),
    {
      orgBalance: v,
      playerBalance: y,
      setPlayerBalance: M,
      setOrgBalance: j,
      permissions: b,
    } = Ze(),
    O = p.useMemo(
      () =>
        !r || r.length === 0
          ? []
          : [
              ...r.filter((k) => {
                const P = a.toLowerCase();
                return (
                  String(k.id).includes(P) || k.name.toLowerCase().includes(P)
                );
              }),
            ].sort((k, P) => {
              let T = 0;
              if (d === "id") T = k.id - P.id;
              else if (d === "name") T = k.name.localeCompare(P.name);
              else if (d === "type") T = k.type.localeCompare(P.type);
              else if (d === "value") T = k.value - P.value;
              else if (d === "date") {
                const V = k.date.split("/").reverse().join("-"),
                  Z = P.date.split("/").reverse().join("-");
                T = new Date(V).getTime() - new Date(Z).getTime();
              }
              return x === "asc" ? T : -T;
            }),
      [r, a, d, x],
    ),
    H = (N) => {
      d === N ? h(x === "asc" ? "desc" : "asc") : (m(N), h("asc"));
    };
  return (
    kn("UpdateExtracts", s),
    kn("UpdateBalance", j),
    kn("UpdatePlayerBalance", M),
    p.useEffect(() => {
      se("GetExtracts", {}, [
        {
          id: 1001,
          name: "Ana Costa",
          type: "deposit",
          value: 8500,
          date: "02/09/2024",
        },
        {
          id: 1002,
          name: "Luiz Silva",
          type: "withdraw",
          value: 2500,
          date: "10/09/2024",
        },
        {
          id: 1003,
          name: "Marina Souza",
          type: "deposit",
          value: 15700,
          date: "14/09/2024",
        },
        {
          id: 1004,
          name: "Carlos Pereira",
          type: "withdraw",
          value: 7800,
          date: "23/09/2024",
        },
        {
          id: 1005,
          name: "Pedro Ramos",
          type: "deposit",
          value: 3200,
          date: "28/09/2024",
        },
        {
          id: 1006,
          name: "Juliana Martins",
          type: "withdraw",
          value: 1800,
          date: "30/09/2024",
        },
        {
          id: 1007,
          name: "Lucas Lima",
          type: "deposit",
          value: 9100,
          date: "01/10/2024",
        },
        {
          id: 1008,
          name: "Amanda Dias",
          type: "deposit",
          value: 4500,
          date: "03/10/2024",
        },
        {
          id: 1009,
          name: "Marcelo Borges",
          type: "withdraw",
          value: 5600,
          date: "04/10/2024",
        },
        {
          id: 1010,
          name: "Roberta Faria",
          type: "deposit",
          value: 2e3,
          date: "05/10/2024",
        },
        {
          id: 1011,
          name: "Cláudia Fonseca",
          type: "withdraw",
          value: 3e3,
          date: "06/10/2024",
        },
        {
          id: 1012,
          name: "Fernando Nunes",
          type: "deposit",
          value: 6700,
          date: "07/10/2024",
        },
        {
          id: 1013,
          name: "Isabela Pinto",
          type: "withdraw",
          value: 1200,
          date: "08/10/2024",
        },
        {
          id: 1014,
          name: "Henrique Souza",
          type: "deposit",
          value: 8300,
          date: "09/10/2024",
        },
        {
          id: 1015,
          name: "Bianca Rocha",
          type: "withdraw",
          value: 4100,
          date: "10/10/2024",
        },
        {
          id: 1016,
          name: "César Alves",
          type: "deposit",
          value: 2600,
          date: "11/10/2024",
        },
        {
          id: 1017,
          name: "Patrícia Mello",
          type: "withdraw",
          value: 9500,
          date: "12/10/2024",
        },
        {
          id: 1018,
          name: "Eduardo Tavares",
          type: "deposit",
          value: 13800,
          date: "13/10/2024",
        },
        {
          id: 1019,
          name: "Rafaela Menezes",
          type: "withdraw",
          value: 6700,
          date: "14/10/2024",
        },
        {
          id: 1020,
          name: "Gabriel Vieira",
          type: "deposit",
          value: 7400,
          date: "15/10/2024",
        },
      ]).then(s);
    }, []),
    i.jsxs("div", {
      className: "size-full flex flex-col gap-3 overflow-hidden",
      children: [
        i.jsx(e8, {
          orgBalance: v,
          playerBalance: y,
          canDeposit: b.deposit,
          canWithdraw: b.withdraw,
        }),
        i.jsxs("div", {
          className:
            "w-full flex-1 border-[.0625rem] border-white/5 bg-white/[.01] flex flex-col gap-3 rounded-[.3125rem] p-4 overflow-hidden",
          children: [
            i.jsx(t8, { search: a, onSearchChange: c }),
            i.jsxs("div", {
              className: "w-full flex-1 flex flex-col gap-2 overflow-hidden",
              children: [
                i.jsx(n8, { sortStyle: d, sortOrder: x, onToggleSort: H }),
                i.jsx("div", {
                  className:
                    "w-full flex-1 flex flex-col gap-2 overflow-y-auto",
                  children:
                    O.length === 0
                      ? i.jsx("div", {
                          className:
                            "w-full h-full flex items-center justify-center",
                          children: i.jsx("p", {
                            className: "text-white/40 text-sm font-medium",
                            children: a
                              ? "Nenhum resultado encontrado"
                              : "Nenhum extrato disponível",
                          }),
                        })
                      : O.map((N, k) =>
                          i.jsx(r8, { extract: N }, `${N.id}-${k}`),
                        ),
                }),
              ],
            }),
          ],
        }),
      ],
    })
  );
}
function i8({ search: r, setSearch: s, goalsType: a, setGoalstype: c }) {
  return i.jsxs("div", {
    className: "w-full flex items-center justify-between",
    children: [
      i.jsxs("div", {
        className: "flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".5rem",
            height: ".625rem",
            viewBox: "0 0 8 10",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M5.01333 1.17647L4.8 0H0V10H1.06667V5.88235H4.05333L4.26667 7.05882H8V1.17647H5.01333Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
          i.jsx("h2", {
            className: "text-white text-xs font-bold",
            children: a === 0 ? "METAS PESSOAIS" : "METAS MEMBROS",
          }),
        ],
      }),
      i.jsxs("div", {
        className: "flex items-center gap-3",
        children: [
          i.jsxs("div", {
            className:
              "w-[15rem] h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4 flex items-center gap-2",
            children: [
              i.jsx("svg", {
                width: ".75rem",
                height: ".75rem",
                viewBox: "0 0 12 12",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                children: i.jsx("path", {
                  d: "M9.46992 8.63464L12 11.1641L11.1641 12L8.63464 9.46992C7.69346 10.2244 6.52279 10.6348 5.31653 10.6331C2.38181 10.6331 0 8.25126 0 5.31653C0 2.38181 2.38181 0 5.31653 0C8.25126 0 10.6331 2.38181 10.6331 5.31653C10.6348 6.52279 10.2244 7.69346 9.46992 8.63464ZM8.28493 8.19632C9.03446 7.42525 9.45312 6.39187 9.45161 5.31653C9.45161 3.03219 7.60087 1.18145 5.31653 1.18145C3.03219 1.18145 1.18145 3.03219 1.18145 5.31653C1.18145 7.60087 3.03219 9.45161 5.31653 9.45161C6.39187 9.45312 7.42525 9.03446 8.19632 8.28493L8.28493 8.19632Z",
                  fill: "white",
                  fillOpacity: "0.25",
                }),
              }),
              i.jsx("input", {
                type: "text",
                placeholder: "PESQUISAR...",
                value: r,
                onChange: (d) => s(d.target.value),
                className:
                  "flex-1 h-full bg-transparent text-white/35 text-xs font-medium placeholder:text-white/35",
              }),
            ],
          }),
          i.jsx("button", {
            onClick: () => c(0),
            className: ne(
              "h-8 border-[.0625rem] text-xs font-bold px-[1.625rem] rounded-[.3125rem]",
              a === 0
                ? "bg-[#ff4848ff] text-[#151716] border-white/35"
                : "border-[#ff4848ff] text-[#ff4848ff]",
            ),
            children: "METAS PESSOAIS",
          }),
          i.jsx("button", {
            onClick: () => c(1),
            className: ne(
              "h-8 border-[.0625rem] text-xs font-bold px-[1.625rem] rounded-[.3125rem]",
              a === 1
                ? "bg-[#ff4848ff] text-[#151716] border-white/35"
                : "border-[#ff4848ff] text-[#ff4848ff]",
            ),
            children: "METAS MEMBROS",
          }),
        ],
      }),
    ],
  });
}
function s8({ index: r }) {
  var j, b, O, H, N, k, P, T;
  const { goals: s, update: a, setOpenedEditGoal: c } = Ze(),
    [d, m] = p.useState(
      ((b = (j = s == null ? void 0 : s.my) == null ? void 0 : j[r]) == null
        ? void 0
        : b.max) ?? 0,
    );
  function x() {
    var V;
    (V = s == null ? void 0 : s.my) != null &&
      V[r] &&
      ((s.my[r].needed = !s.my[r].needed), a({ goals: s }));
  }
  const h = p.useCallback(
      (V) => {
        var Z;
        (m(V),
          (Z = s == null ? void 0 : s.my) != null &&
            Z[r] &&
            ((s.my[r].max = V), a({ goals: s })));
      },
      [s, r, a],
    ),
    v = () => {
      const V = d + 1;
      h(V);
    },
    y = () => {
      const V = Math.max(0, d - 1);
      h(V);
    };
  function M() {
    se(
      "EditMyGoal",
      {
        payment: s == null ? void 0 : s.prize,
        items: s == null ? void 0 : s.my,
      },
      s,
    ).then(() => {
      c(!1);
    });
  }
  return i.jsxs(jt, {
    children: [
      i.jsx(Nt, {
        asChild: !0,
        children: i.jsx("div", {
          className: "w-1/3 flex items-center justify-end",
          children: i.jsx("button", {
            className:
              "text-white/35 text-xs font-bold px-[1.625rem] h-[1.625rem] flex items-center justify-center bg-white/[.03] rounded-[.3125rem]",
            children: "EDITAR",
          }),
        }),
      }),
      i.jsxs(Lt, {
        children: [
          i.jsx(Et, { className: "fixed inset-0 bg-[#101010]/80" }),
          i.jsxs(St, {
            className:
              "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[25rem] px-[1.5625rem] pt-[2.1875rem] pb-[1.5625rem] rounded-xl flex flex-col items-center gap-4 border-[.0563rem] border-white/30 bg-[#101010]/90",
            children: [
              i.jsxs("div", {
                className: "flex items-center gap-2 w-full",
                children: [
                  i.jsx("svg", {
                    width: ".5rem",
                    height: ".625rem",
                    viewBox: "0 0 8 10",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      d: "M5.01333 1.17647L4.8 0H0V10H1.06667V5.88235H4.05333L4.26667 7.05882H8V1.17647H5.01333Z",
                      fill: "white",
                      fillOpacity: "0.25",
                    }),
                  }),
                  i.jsx("h2", {
                    className: "text-white/65 text-sm font-bold",
                    children: "EDITAR QUANTIDADE",
                  }),
                ],
              }),
              i.jsx("img", {
                src: "",
                className: "size-[8.5rem] object-contain",
              }),
              i.jsx("p", {
                className: "text-white text-base font-semibold",
                children:
                  ((H =
                    (O = s == null ? void 0 : s.my) == null ? void 0 : O[r]) ==
                  null
                    ? void 0
                    : H.name) ?? "",
              }),
              i.jsxs("div", {
                className: "w-full flex flex-col gap-1.5",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-normal",
                    children: "QUANTIDADE",
                  }),
                  i.jsxs("div", {
                    className:
                      "w-full h-12 bg-white/[.04] border-[.0625rem] border-white/[.08] px-4 flex items-center justify-between",
                    children: [
                      i.jsx("button", {
                        onClick: y,
                        className:
                          "size-[1.625rem] bg-white/[.03] flex items-center justify-center rounded-[.3125rem] text-white/35 text-xs font-bold cursor-pointer hover:bg-white/[.05]",
                        children: "-",
                      }),
                      i.jsx("input", {
                        type: "number",
                        value: d,
                        onChange: (V) => h(Number(V.target.value)),
                        className:
                          "flex-1 bg-transparent outline-none placeholder:text-white/45 text-xs text-white/45 text-center",
                      }),
                      i.jsx("button", {
                        onClick: v,
                        className:
                          "size-[1.625rem] bg-white/[.03] flex items-center justify-center rounded-[.3125rem] text-white/35 text-xs font-bold cursor-pointer hover:bg-white/[.05]",
                        children: "+",
                      }),
                    ],
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center justify-between",
                children: [
                  i.jsx("span", {
                    className: "text-white text-sm font-bold",
                    children: "ATIVAR META",
                  }),
                  i.jsx("div", {
                    onClick: x,
                    className: ne(
                      "w-10 h-[1.3125rem] flex-none relative rounded-lg border border-[#DDDDDD]/20 bg-[#DDDDDD]/30 cursor-pointer",
                      ((k =
                        (N = s == null ? void 0 : s.my) == null
                          ? void 0
                          : N[r]) == null
                        ? void 0
                        : k.needed) && "!bg-[#ff4848ff] !border-transparent",
                    ),
                    children: i.jsx("div", {
                      className: ne(
                        "absolute top-1/2 -translate-y-1/2 left-[.1875rem] rounded-[.3125rem] bg-[#DDDDDD]/40 size-[.9375rem] duration-300",
                        ((T =
                          (P = s == null ? void 0 : s.my) == null
                            ? void 0
                            : P[r]) == null
                          ? void 0
                          : T.needed) && "!left-[1.375rem] !bg-[#151716]",
                      ),
                    }),
                  }),
                ],
              }),
              i.jsxs("div", {
                className: "w-full flex items-center gap-2",
                children: [
                  i.jsx(qe, {
                    className:
                      "w-[7.5rem] h-8 bg-white/5 rounded-[.3125rem] text-white/25 text-sm font-bold",
                    children: "FECHAR",
                  }),
                  i.jsx(qe, {
                    asChild: !0,
                    children: i.jsx("button", {
                      onClick: M,
                      className:
                        "flex-1 h-8 bg-[#ff4848ff] border-[.0625rem] border-white/35 rounded-[.3125rem] text-[#151716] text-sm font-bold",
                      children: "EDITAR",
                    }),
                  }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function o8({ goal: r, index: s }) {
  return i.jsxs("div", {
    className:
      "w-full h-16 bg-white/[.04] rounded-[.3125rem] flex items-center px-4 flex-none",
    children: [
      i.jsxs("div", {
        className: "flex items-center gap-6 w-1/3",
        children: [
          i.jsx("img", {
            src:
              "http://127.0.0.1/images/" +
              r.item +
              ".png",
            className: "size-10 object-contain",
          }),
          i.jsx("p", {
            className: "text-white text-xs font-semibold",
            children: r.name,
          }),
        ],
      }),
      i.jsxs("p", {
        className: "text-white text-xs font-semibold w-1/3",
        children: [r.current, "/", r.max],
      }),
      i.jsx(s8, { index: s }),
    ],
  });
}
function a8({ goals: r }) {
  return i.jsxs("div", {
    className: "w-full flex-1 flex flex-col gap-3 overflow-hidden",
    children: [
      i.jsx("p", {
        className:
          "w-full h-8 border-[.0625rem] border-white/5 rounded-[.3125rem] px-4 text-white/45 text-xs font-semibold uppercase flex items-center flex-none",
        children:
          "Defina as metas individuais dos membros da facção, estabelecendo a quantidade necessária para que cada objetivo seja considerado concluído.",
      }),
      i.jsxs("div", {
        className: "w-full flex flex-col gap-2 overflow-hidden",
        children: [
          i.jsxs("div", {
            className:
              "w-full flex items-center h-8 bg-white/[.02] px-4 rounded-[.3125rem] flex-none",
            children: [
              i.jsx("p", {
                className: "text-white/60 text-xs font-semibold w-1/3",
                children: "FARM",
              }),
              i.jsx("p", {
                className: "text-white/60 text-xs font-semibold w-1/3",
                children: "QUANTIDADE",
              }),
            ],
          }),
          i.jsx("div", {
            className: "w-full flex-1 flex flex-col gap-2 overflow-y-auto",
            children:
              r == null
                ? void 0
                : r.map((s, a) => i.jsx(o8, { goal: s, index: a }, a)),
          }),
        ],
      }),
    ],
  });
}
function u8({ status: r }) {
  return r === 1
    ? i.jsxs("svg", {
        width: "1.875rem",
        height: "1.6875rem",
        viewBox: "0 0 30 27",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        children: [
          i.jsx("path", {
            d: "M0 13.5L7.5 6.78619e-07L22.5 0L30 13.5L22.5 27L7.5 27L0 13.5Z",
            fill: "#67C32E",
            fillOpacity: "0.2",
          }),
          i.jsx("path", {
            fillRule: "evenodd",
            clipRule: "evenodd",
            d: "M20.64 9.48146C20.804 9.64554 20.8962 9.86806 20.8962 10.1001C20.8962 10.3321 20.804 10.5546 20.64 10.7187L14.0816 17.2771C13.9949 17.3638 13.892 17.4326 13.7787 17.4795C13.6655 17.5264 13.5441 17.5506 13.4215 17.5506C13.2989 17.5506 13.1775 17.5264 13.0643 17.4795C12.951 17.4326 12.8481 17.3638 12.7615 17.2771L9.50297 14.0192C9.4194 13.9385 9.35274 13.8419 9.30688 13.7352C9.26102 13.6284 9.23688 13.5136 9.23587 13.3974C9.23486 13.2812 9.257 13.166 9.301 13.0585C9.34499 12.951 9.40997 12.8533 9.49212 12.7711C9.57428 12.689 9.67197 12.624 9.77951 12.58C9.88704 12.536 10.0023 12.5139 10.1184 12.5149C10.2346 12.5159 10.3494 12.54 10.4562 12.5859C10.5629 12.6317 10.6595 12.6984 10.7402 12.782L13.4212 15.463L19.4021 9.48146C19.4834 9.40014 19.5799 9.33564 19.6861 9.29163C19.7923 9.24763 19.9061 9.22498 20.0211 9.22498C20.136 9.22498 20.2498 9.24763 20.356 9.29163C20.4622 9.33564 20.5587 9.40014 20.64 9.48146Z",
            fill: "#67C32E",
          }),
        ],
      })
    : r === 2
      ? i.jsxs("svg", {
          width: "1.875rem",
          height: "1.6875rem",
          viewBox: "0 0 30 27",
          fill: "none",
          xmlns: "http://www.w3.org/2000/svg",
          children: [
            i.jsx("path", {
              d: "M0 13.5L7.5 6.78619e-07L22.5 0L30 13.5L22.5 27L7.5 27L0 13.5Z",
              fill: "#C33C2E",
              fillOpacity: "0.2",
            }),
            i.jsx("path", {
              fillRule: "evenodd",
              clipRule: "evenodd",
              d: "M15.2201 14.846L18.5877 18.2098C18.7664 18.3883 19.0088 18.4886 19.2615 18.4886C19.5142 18.4886 19.7566 18.3883 19.9353 18.2098C20.114 18.0313 20.2144 17.7893 20.2144 17.5368C20.2144 17.2844 20.114 17.0423 19.9353 16.8638L16.5663 13.5L19.9346 10.1362C20.0231 10.0478 20.0932 9.94289 20.1411 9.82743C20.1889 9.71197 20.2135 9.58823 20.2135 9.46327C20.2135 9.33831 20.1888 9.21458 20.1409 9.09914C20.093 8.9837 20.0228 8.87882 19.9343 8.79048C19.8458 8.70214 19.7408 8.63207 19.6252 8.58428C19.5096 8.53648 19.3857 8.5119 19.2606 8.51193C19.1355 8.51196 19.0116 8.5366 18.8961 8.58445C18.7805 8.6323 18.6755 8.70241 18.5871 8.7908L15.2201 12.1546L11.8524 8.7908C11.7646 8.69988 11.6595 8.62734 11.5433 8.57742C11.4271 8.5275 11.3021 8.5012 11.1756 8.50004C11.0492 8.49888 10.9237 8.5229 10.8066 8.57068C10.6895 8.61847 10.5832 8.68907 10.4937 8.77837C10.4042 8.86766 10.3334 8.97386 10.2855 9.09077C10.2375 9.20768 10.2133 9.33296 10.2144 9.4593C10.2154 9.58564 10.2416 9.7105 10.2915 9.82661C10.3414 9.94272 10.4139 10.0477 10.5048 10.1356L13.8738 13.5L10.5055 16.8644C10.4145 16.9523 10.342 17.0573 10.2921 17.1734C10.2423 17.2895 10.2161 17.4144 10.215 17.5407C10.214 17.667 10.2381 17.7923 10.2861 17.9092C10.334 18.0261 10.4048 18.1323 10.4943 18.2216C10.5838 18.3109 10.6902 18.3815 10.8073 18.4293C10.9244 18.4771 11.0498 18.5011 11.1763 18.5C11.3028 18.4988 11.4277 18.4725 11.5439 18.4226C11.6601 18.3727 11.7652 18.3001 11.853 18.2092L15.2201 14.846Z",
              fill: "#C33C2E",
            }),
          ],
        })
      : r === 3
        ? i.jsxs("svg", {
            width: "1.875rem",
            height: "1.6875rem",
            viewBox: "0 0 30 27",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
              i.jsx("path", {
                d: "M0 13.5L7.5 6.78619e-07L22.5 0L30 13.5L22.5 27L7.5 27L0 13.5Z",
                fill: "#989898",
                fillOpacity: "0.2",
              }),
              i.jsx("path", {
                d: "M22.2051 0.5L29.4268 13.5L22.2051 26.5H7.79492L0.572266 13.5L7.79492 0.5H22.2051Z",
                stroke: "white",
                strokeOpacity: "0.15",
              }),
              i.jsx("path", {
                d: "M17.5714 9.16995C18.3255 9.60537 18.9529 10.2302 19.3913 10.9826C19.8298 11.735 20.0641 12.5888 20.0711 13.4596C20.0782 14.3304 19.8576 15.1879 19.4314 15.9473C19.0052 16.7067 18.388 17.3416 17.641 17.7891C16.894 18.2367 16.043 18.4814 15.1724 18.499C14.3018 18.5166 13.4416 18.3065 12.6771 17.8896C11.9126 17.4726 11.2702 16.8632 10.8136 16.1217C10.357 15.3802 10.102 14.5323 10.0738 13.6619L10.0713 13.4999L10.0738 13.3379C10.1018 12.4744 10.3531 11.6329 10.8031 10.8954C11.2532 10.158 11.8866 9.54967 12.6418 9.12989C13.3969 8.7101 14.2479 8.49314 15.1119 8.50017C15.9758 8.50719 16.8232 8.73795 17.5714 9.16995ZM15.0714 10.4999C14.9489 10.5 14.8307 10.5449 14.7392 10.6263C14.6476 10.7077 14.5892 10.8198 14.5748 10.9414L14.5713 10.9999V13.4999L14.5758 13.5654C14.5872 13.6522 14.6212 13.7344 14.6743 13.8039L14.7178 13.8539L16.2179 15.3539L16.2649 15.3949C16.3526 15.463 16.4604 15.4999 16.5714 15.4999C16.6824 15.4999 16.7902 15.463 16.8779 15.3949L16.9249 15.3534L16.9664 15.3064C17.0344 15.2188 17.0713 15.1109 17.0713 14.9999C17.0713 14.889 17.0344 14.7811 16.9664 14.6934L16.9249 14.6464L15.5714 13.2924V10.9999L15.5679 10.9414C15.5535 10.8198 15.4951 10.7077 15.4035 10.6263C15.312 10.5449 15.1938 10.5 15.0714 10.4999Z",
                fill: "#989898",
              }),
            ],
          })
        : i.jsxs("svg", {
            width: "1.875rem",
            height: "1.6875rem",
            viewBox: "0 0 30 27",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: [
              i.jsx("path", {
                d: "M0 13.5L7.5 6.78619e-07L22.5 0L30 13.5L22.5 27L7.5 27L0 13.5Z",
                fill: "#989898",
                fillOpacity: "0.05",
              }),
              i.jsx("path", {
                d: "M16.0846 9.67647L15.8713 8.5H11.0713V18.5H12.138V14.3824H15.1246L15.338 15.5588H19.0713V9.67647H16.0846Z",
                fill: "white",
                fillOpacity: "0.15",
              }),
            ],
          });
}
function c8({ member: r }) {
  return i.jsxs("div", {
    className:
      "w-full h-[3.125rem] bg-white/[.04] flex items-center px-4 rounded-[.3125rem] flex-none",
    children: [
      i.jsx("p", {
        className: "text-white text-xs font-semibold w-[8rem]",
        children: r.id,
      }),
      i.jsx("p", {
        className: "text-white text-xs font-semibold w-[20rem]",
        children: r.name,
      }),
      i.jsxs("div", {
        className: "flex items-center gap-2 w-[12.5rem]",
        children: [
          i.jsx("img", { src: "", className: "size-6 object-contain" }),
          i.jsx("p", {
            className: "text-white text-xs font-semibold",
            children: "FARM",
          }),
          i.jsx("p", {
            className: "text-white/45 text-xs font-medium",
            children: "-/-",
          }),
        ],
      }),
      i.jsx("div", {
        className: "flex items-center gap-2 flex-1",
        children: r.status.map((s, a) =>
          i.jsx(
            "div",
            {
              className: "flex-1 flex items-center justify-center",
              children: i.jsx(u8, { status: s }),
            },
            a,
          ),
        ),
      }),
    ],
  });
}
function d8({ members: r }) {
  return i.jsxs("div", {
    className: "w-full flex-1 flex flex-col gap-2 overflow-hidden",
    children: [
      i.jsxs("div", {
        className:
          "w-full flex items-center h-8 bg-white/[.02] px-4 rounded-[.3125rem] flex-none",
        children: [
          i.jsx("p", {
            className: "text-white/60 text-xs font-semibold w-[8rem]",
            children: "ID",
          }),
          i.jsx("p", {
            className: "text-white/60 text-xs font-semibold w-[20rem]",
            children: "NOME",
          }),
          i.jsx("p", {
            className: "text-white/60 text-xs font-semibold w-[12.5rem]",
            children: "FARM",
          }),
          i.jsxs("div", {
            className: "flex items-center flex-1 gap-2",
            children: [
              i.jsx("p", {
                className:
                  "text-white/60 text-xs font-semibold uppercase flex-1 text-center",
                children: "dom",
              }),
              i.jsx("p", {
                className:
                  "text-white/60 text-xs font-semibold uppercase flex-1 text-center",
                children: "SEG",
              }),
              i.jsx("p", {
                className:
                  "text-white/60 text-xs font-semibold uppercase flex-1 text-center",
                children: "ter",
              }),
              i.jsx("p", {
                className:
                  "text-white/60 text-xs font-semibold uppercase flex-1 text-center",
                children: "qua",
              }),
              i.jsx("p", {
                className:
                  "text-white/60 text-xs font-semibold uppercase flex-1 text-center",
                children: "qui",
              }),
              i.jsx("p", {
                className:
                  "text-white/60 text-xs font-semibold uppercase flex-1 text-center",
                children: "sex",
              }),
              i.jsx("p", {
                className:
                  "text-white/60 text-xs font-semibold uppercase flex-1 text-center",
                children: "sáb",
              }),
            ],
          }),
        ],
      }),
      i.jsx("div", {
        className: "w-full flex-1 flex flex-col gap-2 overflow-y-auto",
        children:
          r == null ? void 0 : r.map((s) => i.jsx(c8, { member: s }, s.id)),
      }),
    ],
  });
}
function f8() {
  var h;
  const [r, s] = p.useState(""),
    [a, c] = p.useState(0),
    { goals: d, setGoals: m } = Ze(),
    x =
      (h = d == null ? void 0 : d.members) == null
        ? void 0
        : h.filter(
            (v) =>
              String(v.id) === r ||
              v.name.toLocaleLowerCase().includes(r.toLocaleLowerCase()),
          );
  return (
    p.useEffect(() => {
      se(
        "GetGoals",
        {},
        {
          prize: "222.02",
          my: [
            { name: "ITEM1", item: "test1", needed: !0, current: 20, max: 20 },
            { name: "ITEM1", item: "test2", needed: !1, current: 20, max: 20 },
            { name: "ITEM1", item: "test3", needed: !0, current: 2, max: 20 },
          ],
          faction: [
            {
              title: "test1",
              description: "testsetstsdscasd",
              current: 10,
              max: 40,
            },
            {
              title: "test2",
              description: "testsetstsdscasd",
              current: 1,
              max: 50,
            },
            {
              title: "test3",
              description: "testsetstsdscasd",
              current: 1,
              max: 60,
            },
            {
              title: "test4",
              description:
                "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industrys standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. ",
              current: 1,
              max: 10,
            },
            {
              title: "test5",
              description: "testsetstsdscasd",
              current: 1,
              max: 70,
            },
          ],
          members: [
            { name: "João Sembraco", id: 2352, status: [1, 2, 3, 4, 1, 2, 1] },
          ],
        },
      ).then(m);
    }, []),
    i.jsxs("div", {
      className:
        "size-full bg-white/[.01] border-[.0625rem] border-white/5 rounded-[.3125rem] p-4 flex flex-col gap-3 overflow-hidden",
      children: [
        i.jsx(i8, { search: r, setSearch: s, goalsType: a, setGoalstype: c }),
        a === 0 && i.jsx(a8, { goals: (d == null ? void 0 : d.my) || [] }),
        a === 1 && i.jsx(d8, { members: x || [] }),
      ],
    })
  );
}
function m8({ sortType: r, onSortChange: s }) {
  const a = [
    { type: "timePlayed", label: "ONLINES" },
    { type: "money", label: "DINHEIRO" },
    { type: "farm", label: "FARM" },
  ];
  return i.jsx("div", {
    className: "flex items-center gap-3",
    children: a.map((c) =>
      i.jsx(
        "button",
        {
          onClick: () => s(c.type),
          className: ne(
            "text-xs font-bold h-8 border-[.0625rem] rounded-[.3125rem] px-[1.625rem] transition-colors",
            r === c.type
              ? "text-[#151716] border-white/30 bg-[#ff4848ff]"
              : "text-white/50 border-white/20 hover:text-white/70 hover:border-white/30",
          ),
          children: c.label,
        },
        c.type,
      ),
    ),
  });
}
function h8({ sortType: r, onSortChange: s }) {
  return i.jsxs("div", {
    className: "w-full flex items-center justify-between",
    children: [
      i.jsxs("div", {
        className: "flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".75rem",
            height: ".6875rem",
            viewBox: "0 0 12 11",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M8.33333 0H3.66667C3.11458 0 2.66458 0.468359 2.68542 1.03555C2.68958 1.14941 2.69375 1.26328 2.7 1.375H0.5C0.222917 1.375 0 1.60488 0 1.89062C0 3.88008 0.697917 5.26367 1.63542 6.20254C2.55833 7.12852 3.68333 7.59473 4.5125 7.83105C5 7.9707 5.33333 8.38965 5.33333 8.81074C5.33333 9.25977 4.97917 9.625 4.54375 9.625H4C3.63125 9.625 3.33333 9.93223 3.33333 10.3125C3.33333 10.6928 3.63125 11 4 11H8C8.36875 11 8.66667 10.6928 8.66667 10.3125C8.66667 9.93223 8.36875 9.625 8 9.625H7.45625C7.02083 9.625 6.66667 9.25977 6.66667 8.81074C6.66667 8.38965 6.99792 7.96855 7.4875 7.83105C8.31875 7.59473 9.44375 7.12852 10.3667 6.20254C11.3021 5.26367 12 3.88008 12 1.89062C12 1.60488 11.7771 1.375 11.5 1.375H9.3C9.30625 1.26328 9.31042 1.15156 9.31458 1.03555C9.33542 0.468359 8.88542 0 8.33333 0ZM1.01875 2.40625H2.77708C2.96667 4.34199 3.38542 5.63535 3.85833 6.50117C3.33958 6.26484 2.8 5.93184 2.33333 5.46348C1.66667 4.79531 1.125 3.83066 1.02083 2.40625H1.01875ZM9.66875 5.46348C9.20208 5.93184 8.6625 6.26484 8.14375 6.50117C8.61667 5.63535 9.03542 4.34199 9.225 2.40625H10.9833C10.8771 3.83066 10.3354 4.79531 9.67083 5.46348H9.66875Z",
              fill: "white",
              fillOpacity: "0.25",
            }),
          }),
          i.jsx("h2", {
            className: "text-white text-xs font-bold",
            children: "RANKING",
          }),
        ],
      }),
      i.jsx(m8, { sortType: r, onSortChange: s }),
    ],
  });
}
function p8({ position: r, isUser: s }) {
  const a = () =>
      r === 1 ? "#ff4848ff" : r === 2 ? "#BEBEBE" : r === 3 ? "#CD886B" : "white",
    c = () => (r <= 3 ? 1 : 0.05),
    d = () =>
      r === 1
        ? "text-[#FFD700]"
        : r === 2
          ? "text-[#C0C0C0]"
          : r === 3
            ? "text-[#CD7F32]"
            : s
              ? "text-[#ff4848ff]"
              : "text-white/50";
  return r > 3
    ? i.jsxs("div", {
        className:
          "w-[1.8789rem] h-[1.625rem] relative flex items-center justify-center",
        children: [
          i.jsx("svg", {
            className: "absolute top-0 left-0",
            width: "1.9375rem",
            height: "1.625rem",
            viewBox: "0 0 31 26",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M0 13L7.51562 6.53485e-07L22.5469 0L30.0625 13L22.5469 26L7.51563 26L0 13Z",
              fill: a(),
              fillOpacity: c(),
            }),
          }),
          i.jsxs("p", {
            className: `text-[.6875rem] font-medium z-10 ${d()}`,
            children: [r, "°"],
          }),
        ],
      })
    : i.jsxs("svg", {
        width: "1.9375rem",
        height: "1.625rem",
        viewBox: "0 0 31 26",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        children: [
          i.jsx("path", {
            d: "M0 13L7.51562 6.53485e-07L22.5469 0L30.0625 13L22.5469 26L7.51563 26L0 13Z",
            fill: a(),
          }),
          i.jsx("path", {
            d: "M17.9653 7.3125H12.9097C12.3116 7.3125 11.8241 7.79683 11.8467 8.38335C11.8512 8.5011 11.8557 8.61885 11.8625 8.73438H9.47917C9.17899 8.73438 8.9375 8.97209 8.9375 9.26758C8.9375 11.3249 9.69358 12.7556 10.7092 13.7265C11.709 14.684 12.9278 15.1661 13.826 15.4105C14.3542 15.5549 14.7153 15.9882 14.7153 16.4236C14.7153 16.8879 14.3316 17.2656 13.8599 17.2656H13.2708C12.8714 17.2656 12.5486 17.5833 12.5486 17.9766C12.5486 18.3698 12.8714 18.6875 13.2708 18.6875H17.6042C18.0036 18.6875 18.3264 18.3698 18.3264 17.9766C18.3264 17.5833 18.0036 17.2656 17.6042 17.2656H17.0151C16.5434 17.2656 16.1597 16.8879 16.1597 16.4236C16.1597 15.9882 16.5186 15.5527 17.049 15.4105C17.9495 15.1661 19.1682 14.684 20.1681 13.7265C21.1814 12.7556 21.9375 11.3249 21.9375 9.26758C21.9375 8.97209 21.696 8.73438 21.3958 8.73438H19.0125C19.0193 8.61885 19.0238 8.50332 19.0283 8.38335C19.0509 7.79683 18.5634 7.3125 17.9653 7.3125ZM10.0411 9.80078H11.946C12.1514 11.8025 12.605 13.14 13.1174 14.0353C12.5554 13.7909 11.9708 13.4466 11.4653 12.9622C10.7431 12.2713 10.1562 11.2738 10.0434 9.80078H10.0411ZM19.412 12.9622C18.9064 13.4466 18.3219 13.7909 17.7599 14.0353C18.2722 13.14 18.7259 11.8025 18.9312 9.80078H20.8361C20.721 11.2738 20.1342 12.2713 19.4142 12.9622H19.412Z",
            fill: "#171918",
          }),
        ],
      });
}
function x8({ id: r, name: s, value: a, position: c, isUser: d }) {
  const m = c - 1;
  return i.jsxs("div", {
    className: ne(
      "w-full h-10 bg-white/[.04] flex items-center px-4 rounded-[.3125rem] flex-none border-[.0625rem] border-transparent",
      d && "!bg-[#ff4848ff]/10 border-[#ff4848ff]/30",
      m === 0 && "!bg-[#ff4848ff]/5 !border-[#ff4848ff]",
      m === 1 && "!bg-[#BEBEBE]/5 !border-[#BEBEBE]",
      m === 2 && "!bg-[#CD886B]/5 !border-[#CD886B]",
    ),
    children: [
      i.jsx("div", {
        className: "w-[4.5rem]",
        children: i.jsx(p8, { position: c, isUser: d }),
      }),
      i.jsxs("div", {
        className: "flex items-center gap-1.5 w-[37.6875rem]",
        children: [
          i.jsx("p", {
            className: ne(
              "text-xs font-semibold uppercase",
              d ? "text-[#ff4848ff]" : "text-white",
            ),
            children: s,
          }),
          i.jsx("span", {
            className: ne(
              "text-xs font-medium h-5 px-1.5 rounded flex items-center justify-center",
              d
                ? "text-[#ff4848ff] bg-[#ff4848ff]/20"
                : "text-white/50 bg-white/[.08]",
            ),
            children: r,
          }),
        ],
      }),
      i.jsx("p", {
        className: ne(
          "text-xs font-medium w-[37.6875rem] text-right",
          d ? "text-[#ff4848ff]/80" : "text-white/45",
          m === 0 && "!text-[#ff4848ff]",
          m === 1 && "!text-[#BEBEBE]",
          m === 2 && "!text-[#CD886B]",
        ),
        children: a,
      }),
    ],
  });
}
function C8() {
  const { user_id: r } = Ze(),
    [s, a] = p.useState([]),
    [c, d] = p.useState("timePlayed");
  p.useEffect(() => {
    se("GetRanking", null, [
      {
        id: 1337,
        name: "João Sembraco",
        timePlayed: 1234,
        money: 5678,
        farm: 910,
      },
      { id: 2, name: "Maria Silva", timePlayed: 2345, money: 6789, farm: 123 },
      {
        id: 3,
        name: "Carlos Oliveira",
        timePlayed: 3456,
        money: 7890,
        farm: 456,
      },
      { id: 4, name: "Ana Costa", timePlayed: 4567, money: 8901, farm: 789 },
      { id: 5, name: "Pedro Santos", timePlayed: 5678, money: 9012, farm: 234 },
      {
        id: 6,
        name: "Lucas Almeida",
        timePlayed: 6789,
        money: 1234,
        farm: 567,
      },
    ]).then(a);
  }, []);
  const m = p.useMemo(
      () =>
        (s == null
          ? void 0
          : s.sort((h, v) =>
              c === "timePlayed"
                ? v.timePlayed - h.timePlayed
                : c === "money"
                  ? v.money - h.money
                  : c === "farm"
                    ? v.farm - h.farm
                    : 0,
            )) || [],
      [c, s],
    ),
    x = (h) =>
      c === "timePlayed"
        ? `${Math.floor(Number(h.timePlayed) / 60)}H ${Number(h.timePlayed) % 60} MINUTOS`
        : c === "money"
          ? `R$ ${Number(h.money).toLocaleString("pt-BR")}`
          : c === "farm"
            ? Number(h.farm).toLocaleString("pt-BR")
            : "";
  return i.jsxs("div", {
    className:
      "size-full bg-white/[.01] border-[.0625rem] border-white/5 rounded-[.3125rem] p-4 flex flex-col gap-3",
    children: [
      i.jsx(h8, { sortType: c, onSortChange: d }),
      i.jsx("div", {
        className: "w-full flex-1 flex flex-col gap-2 overflow-y-auto",
        children: m.map((h, v) =>
          i.jsx(
            x8,
            {
              id: h.id,
              name: h.name,
              value: x(h),
              position: v + 1,
              isUser: h.id === r,
            },
            `${h.id}-${v}`,
          ),
        ),
      }),
    ],
  });
}
function v8({
  selectedFilter: r,
  isDropdownOpen: s,
  filters: a,
  search: c,
  onFilterToggle: d,
  onFilterSelect: m,
  onSearchChange: x,
}) {
  var h;
  return i.jsxs("div", {
    className: "w-full flex items-center justify-between",
    children: [
      i.jsxs("div", {
        className: "flex items-center gap-2",
        children: [
          i.jsx("svg", {
            width: ".625rem",
            height: ".625rem",
            viewBox: "0 0 10 10",
            fill: "none",
            xmlns: "http://www.w3.org/2000/svg",
            children: i.jsx("path", {
              d: "M7.50009 0.669946C8.25423 1.10537 8.88158 1.73021 9.32002 2.4826C9.75847 3.23498 9.9928 4.08883 9.99984 4.95962C10.0069 5.8304 9.78636 6.68792 9.36013 7.44729C8.93389 8.20667 8.31672 8.84155 7.56971 9.2891C6.8227 9.73666 5.97176 9.98136 5.10111 9.99898C4.23047 10.0166 3.37032 9.80653 2.60581 9.38957C1.8413 8.9726 1.19895 8.36321 0.742342 7.6217C0.285735 6.8802 0.030705 6.0323 0.00250009 5.16195L0 4.99995L0.00250009 4.83794C0.030502 3.97444 0.281777 3.13293 0.731829 2.39544C1.18188 1.65796 1.81535 1.04967 2.57048 0.629887C3.32561 0.210103 4.17662 -0.00685539 5.04057 0.000165123C5.90451 0.00718564 6.75189 0.237945 7.50009 0.669946ZM5.00006 1.99995C4.87759 1.99996 4.75939 2.04492 4.66787 2.1263C4.57635 2.20768 4.51788 2.31982 4.50356 2.44145L4.50006 2.49995V4.99995L4.50456 5.06544C4.51596 5.15219 4.54992 5.23443 4.60306 5.30395L4.64656 5.35395L6.14658 6.85394L6.19358 6.89494C6.28126 6.96298 6.38909 6.9999 6.50008 6.9999C6.61106 6.9999 6.7189 6.96298 6.80658 6.89494L6.85358 6.85344L6.89508 6.80644C6.96312 6.71876 7.00004 6.61093 7.00004 6.49995C7.00004 6.38896 6.96312 6.28113 6.89508 6.19345L6.85358 6.14645L5.50007 4.79245V2.49995L5.49657 2.44145C5.48224 2.31982 5.42377 2.20768 5.33225 2.1263C5.24073 2.04492 5.12253 1.99996 5.00006 1.99995Z",
              fill: "white",
              "fill-opacity": "0.25",
            }),
          }),
          i.jsx("h2", {
            className: "text-white text-xs font-bold",
            children: "LOGS",
          }),
        ],
      }),
      i.jsxs("div", {
        className: "flex items-center gap-3",
        children: [
          i.jsxs("div", {
            className: "relative",
            children: [
              i.jsxs("button", {
                onClick: d,
                className:
                  "flex items-center gap-1 cursor-pointer hover:opacity-80 transition-opacity",
                children: [
                  i.jsx("p", {
                    className: "text-white/45 text-xs font-medium",
                    children: "FILTRAR POR",
                  }),
                  i.jsx("p", {
                    className: "text-white text-xs font-bold",
                    children:
                      (r &&
                        ((h = a.find((v) => v.value === r)) == null
                          ? void 0
                          : h.label)) ||
                      "TODOS",
                  }),
                  i.jsx("svg", {
                    width: "9",
                    height: "5",
                    viewBox: "0 0 9 5",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    className: ne("transition-transform", s && "rotate-180"),
                    children: i.jsx("path", {
                      fillRule: "evenodd",
                      clipRule: "evenodd",
                      d: "M4.00008 4.8012L-4.19675e-08 0.960104L0.999843 -3.49698e-07L4.5 3.36104L8.00016 -4.37045e-08L9 0.960104L4.99992 4.8012C4.86732 4.92849 4.6875 5 4.5 5C4.3125 5 4.13268 4.92849 4.00008 4.8012Z",
                      fill: "white",
                    }),
                  }),
                ],
              }),
              s &&
                i.jsxs("div", {
                  className:
                    "absolute top-full mt-2 right-0 min-w-[10rem] bg-[#151716]/95 border-[.0625rem] border-white/[.12] rounded-[.3125rem] overflow-hidden z-10",
                  children: [
                    i.jsx("button", {
                      onClick: () => m(null),
                      className: ne(
                        "w-full px-4 py-2 text-left text-xs font-semibold hover:bg-white/[.08] transition-colors",
                        r === null
                          ? "text-white bg-white/[.06]"
                          : "text-white/70",
                      ),
                      children: "TODOS",
                    }),
                    a.map((v) =>
                      i.jsx(
                        "button",
                        {
                          onClick: () => m(v.value),
                          className: ne(
                            "w-full px-4 py-2 text-left text-xs font-semibold hover:bg-white/[.08] transition-colors",
                            r === v.value
                              ? "text-white bg-white/[.06]"
                              : "text-white/70",
                          ),
                          children: v.label,
                        },
                        v.value,
                      ),
                    ),
                  ],
                }),
            ],
          }),
          i.jsxs("div", {
            className:
              "flex items-center gap-2 w-[15rem] h-8 bg-white/[.04] border-[.0625rem] border-white/[.08] rounded-[.3125rem] px-4",
            children: [
              i.jsx("svg", {
                className: "flex-none",
                width: ".75rem",
                height: ".75rem",
                viewBox: "0 0 12 12",
                fill: "none",
                xmlns: "http://www.w3.org/2000/svg",
                children: i.jsx("path", {
                  d: "M9.46992 8.63464L12 11.1641L11.1641 12L8.63464 9.46992C7.69346 10.2244 6.52279 10.6348 5.31653 10.6331C2.38181 10.6331 0 8.25126 0 5.31653C0 2.38181 2.38181 0 5.31653 0C8.25126 0 10.6331 2.38181 10.6331 5.31653C10.6348 6.52279 10.2244 7.69346 9.46992 8.63464ZM8.28493 8.19632C9.03446 7.42525 9.45312 6.39187 9.45161 5.31653C9.45161 3.03219 7.60087 1.18145 5.31653 1.18145C3.03219 1.18145 1.18145 3.03219 1.18145 5.31653C1.18145 7.60087 3.03219 9.45161 5.31653 9.45161C6.39187 9.45312 7.42525 9.03446 8.19632 8.28493L8.28493 8.19632Z",
                  fill: "white",
                  "fill-opacity": "0.25",
                }),
              }),
              i.jsx("input", {
                type: "text",
                placeholder: "PESQUISAR...",
                value: c,
                onChange: (v) => x(v.target.value),
                className:
                  "flex-1 h-full bg-transparent text-white text-xs font-medium placeholder:text-white/35",
              }),
            ],
          }),
        ],
      }),
    ],
  });
}
function g8({ id: r, name: s, type: a, description: c, date: d }) {
  return i.jsxs("div", {
    className:
      "w-full h-10 bg-white/[.04] rounded-[.3125rem] px-4 flex items-center flex-none",
    children: [
      i.jsx("p", {
        className: "text-white text-xs font-semibold w-[8rem] truncate",
        children: r,
      }),
      i.jsx("p", {
        className:
          "text-white text-xs font-semibold w-[17.9688rem] uppercase truncate",
        children: s,
      }),
      i.jsx("div", {
        className: "w-[17.9688rem] flex items-center truncate",
        children: i.jsxs("div", {
          className: `flex items-center gap-1.5 px-1.5 rounded-[.3125rem] w-max h-[1.375rem] truncate ${a === "chest" ? "bg-[#ff4848ff]/[.08]" : a === "hired" ? "bg-[#67C32E]/[.08]" : a === "fired" ? "bg-[#C33C2E]/[.08]" : "bg-[#f63b3bff]/[.08]"}`,
          children: [
            a === "chest"
              ? i.jsx("svg", {
                  width: ".75rem",
                  height: ".75rem",
                  viewBox: "0 0 12 12",
                  fill: "none",
                  xmlns: "http://www.w3.org/2000/svg",
                  children: i.jsx("path", {
                    d: "M9.3468 1.46624L8.1468 0.833199C7.0932 0.277934 6.5664 0 6 0C5.4336 0 4.9068 0.277331 3.8532 0.833199L3.6606 0.935089L9.0144 4.00924L11.424 2.79743C11.0364 2.35611 10.4112 2.02633 9.3468 1.46503M11.8488 3.59566L9.45 4.80145V6.63183C9.45 6.75176 9.40259 6.86677 9.3182 6.95157C9.23381 7.03636 9.11935 7.084 9 7.084C8.88065 7.084 8.76619 7.03636 8.6818 6.95157C8.59741 6.86677 8.55 6.75176 8.55 6.63183V5.25362L6.45 6.30868V12C6.8808 11.8921 7.371 11.634 8.1468 11.2247L9.3468 10.5916C10.6374 9.91097 11.283 9.57094 11.6418 8.959C12 8.34767 12 7.58621 12 6.06511V5.99457C12 4.8533 12 4.13947 11.8488 3.59566ZM5.55 12V6.30868L0.1512 3.59566C5.36442e-08 4.13947 0 4.8533 0 5.99337V6.06391C0 7.58621 -7.15256e-08 8.34767 0.3582 8.959C0.717 9.57094 1.3626 9.91158 2.6532 10.5922L3.8532 11.2247C4.629 11.634 5.1192 11.8921 5.55 12ZM0.576 2.79803L6 5.52311L8.0466 4.49518L2.715 1.43368L2.6532 1.46624C1.5894 2.02693 0.9636 2.35671 0.576 2.79863",
                    fill: "#ff4848ff",
                  }),
                })
              : a === "hired"
                ? i.jsx("svg", {
                    width: ".75rem",
                    height: ".75rem",
                    viewBox: "0 0 12 12",
                    fill: "none",
                    xmlns: "http://www.w3.org/2000/svg",
                    children: i.jsx("path", {
                      d: "M11.9073 11.2611C11.9589 11.3296 11.9903 11.4112 11.9981 11.4967C12.0059 11.5821 11.9897 11.668 11.9513 11.7448C11.913 11.8215 11.854 11.8861 11.781 11.9312C11.708 11.9762 11.6239 12.0001 11.538 12H0.461522C0.375812 12 0.291795 11.9761 0.218886 11.9311C0.145976 11.886 0.087055 11.8216 0.0487243 11.7449C0.0103936 11.6683 -0.00583216 11.5824 0.00186509 11.4971C0.00956233 11.4117 0.0408785 11.3302 0.0923046 11.2617C0.500973 10.7138 1.04594 10.2825 1.67302 10.0105C1.32929 9.69685 1.08844 9.28658 0.982089 8.83359C0.87574 8.38059 0.908857 7.90603 1.07709 7.47219C1.24533 7.03835 1.54083 6.6655 1.9248 6.40259C2.30876 6.13969 2.76326 5.999 3.22863 5.999C3.694 5.999 4.1485 6.13969 4.53247 6.40259C4.91644 6.6655 5.21193 7.03835 5.38017 7.47219C5.54841 7.90603 5.58153 8.38059 5.47518 8.83359C5.36883 9.28658 5.12798 9.69685 4.78425 10.0105C5.23667 10.2061 5.64779 10.4858 5.99574 10.8348C6.3437 10.4858 6.75482 10.2061 7.20724 10.0105C6.86351 9.69685 6.62266 9.28658 6.51631 8.83359C6.40996 8.38059 6.44308 7.90603 6.61132 7.47219C6.77955 7.03835 7.07505 6.6655 7.45902 6.40259C7.84299 6.13969 8.29749 5.999 8.76286 5.999C9.22823 5.999 9.68272 6.13969 10.0667 6.40259C10.4507 6.6655 10.7462 7.03835 10.9144 7.47219C11.0826 7.90603 11.1158 8.38059 11.0094 8.83359C10.9031 9.28658 10.6622 9.69685 10.3185 10.0105C10.9485 10.2811 11.4963 10.7123 11.9073 11.2611ZM0.184609 5.90871C0.233095 5.94507 0.288269 5.97152 0.346981 5.98656C0.405693 6.0016 0.466792 6.00493 0.526791 5.99636C0.58679 5.98779 0.644513 5.96749 0.696664 5.93661C0.748816 5.90574 0.794375 5.8649 0.830739 5.81642C1.11017 5.44389 1.47251 5.14153 1.88906 4.93328C2.30561 4.72503 2.76493 4.61662 3.23065 4.61662C3.69637 4.61662 4.15569 4.72503 4.57224 4.93328C4.9888 5.14153 5.35113 5.44389 5.63057 5.81642C5.67355 5.87373 5.7293 5.92024 5.79338 5.95228C5.85747 5.98432 5.92813 6.001 5.99978 6.001C6.07143 6.001 6.1421 5.98432 6.20618 5.95228C6.27027 5.92024 6.32601 5.87373 6.369 5.81642C6.64843 5.44389 7.01077 5.14153 7.42732 4.93328C7.84387 4.72503 8.30319 4.61662 8.76891 4.61662C9.23463 4.61662 9.69396 4.72503 10.1105 4.93328C10.5271 5.14153 10.8894 5.44389 11.1688 5.81642C11.2052 5.8649 11.2508 5.90573 11.303 5.93659C11.3552 5.96745 11.413 5.98773 11.473 5.99628C11.533 6.00482 11.5941 6.00146 11.6529 5.98638C11.7116 5.97131 11.7668 5.94482 11.8152 5.90842C11.8637 5.87202 11.9046 5.82643 11.9354 5.77425C11.9663 5.72207 11.9866 5.66432 11.9951 5.60431C12.0037 5.54429 12.0003 5.48318 11.9852 5.42446C11.9702 5.36574 11.9437 5.31057 11.9073 5.26209C11.4986 4.71441 10.9536 4.28326 10.3265 4.01152C10.6703 3.69785 10.9111 3.28759 11.0175 2.83459C11.1238 2.38159 11.0907 1.90703 10.9225 1.47319C10.7542 1.03935 10.4587 0.666503 10.0748 0.403595C9.6908 0.140687 9.2363 0 8.77093 0C8.30556 0 7.85106 0.140687 7.4671 0.403595C7.08313 0.666503 6.78763 1.03935 6.61939 1.47319C6.45116 1.90703 6.41804 2.38159 6.52439 2.83459C6.63074 3.28759 6.87159 3.69785 7.21532 4.01152C6.7629 4.20705 6.35177 4.48678 6.00382 4.83581C5.65587 4.48678 5.24474 4.20705 4.79233 4.01152C5.13606 3.69785 5.3769 3.28759 5.48325 2.83459C5.5896 2.38159 5.55649 1.90703 5.38825 1.47319C5.22001 1.03935 4.92452 0.666503 4.54055 0.403595C4.15658 0.140687 3.70208 0 3.23671 0C2.77134 0 2.31684 0.140687 1.93287 0.403595C1.5489 0.666503 1.25341 1.03935 1.08517 1.47319C0.916934 1.90703 0.883816 2.38159 0.990166 2.83459C1.09652 3.28759 1.33736 3.69785 1.68109 4.01152C1.05107 4.28228 0.503205 4.71372 0.0923046 5.26266C0.0559398 5.31114 0.0294812 5.36631 0.0144395 5.42501C-0.000602239 5.48372 -0.0039325 5.54481 0.00463875 5.6048C0.01321 5.66479 0.033515 5.72251 0.0643943 5.77465C0.0952737 5.8268 0.136123 5.87235 0.184609 5.90871Z",
                      fill: "#67C32E",
                    }),
                  })
                : a === "fired"
                  ? i.jsx("svg", {
                      width: ".75rem",
                      height: ".75rem",
                      viewBox: "0 0 12 12",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: i.jsx("path", {
                        d: "M11.9073 11.2611C11.9589 11.3296 11.9903 11.4112 11.9981 11.4967C12.0059 11.5821 11.9897 11.668 11.9513 11.7448C11.913 11.8215 11.854 11.8861 11.781 11.9312C11.708 11.9762 11.6239 12.0001 11.538 12H0.461522C0.375812 12 0.291795 11.9761 0.218886 11.9311C0.145976 11.886 0.087055 11.8216 0.0487243 11.7449C0.0103936 11.6683 -0.00583216 11.5824 0.00186509 11.4971C0.00956233 11.4117 0.0408785 11.3302 0.0923046 11.2617C0.500973 10.7138 1.04594 10.2825 1.67302 10.0105C1.32929 9.69685 1.08844 9.28658 0.982089 8.83359C0.87574 8.38059 0.908857 7.90603 1.07709 7.47219C1.24533 7.03835 1.54083 6.6655 1.9248 6.40259C2.30876 6.13969 2.76326 5.999 3.22863 5.999C3.694 5.999 4.1485 6.13969 4.53247 6.40259C4.91644 6.6655 5.21193 7.03835 5.38017 7.47219C5.54841 7.90603 5.58153 8.38059 5.47518 8.83359C5.36883 9.28658 5.12798 9.69685 4.78425 10.0105C5.23667 10.2061 5.64779 10.4858 5.99574 10.8348C6.3437 10.4858 6.75482 10.2061 7.20724 10.0105C6.86351 9.69685 6.62266 9.28658 6.51631 8.83359C6.40996 8.38059 6.44308 7.90603 6.61132 7.47219C6.77955 7.03835 7.07505 6.6655 7.45902 6.40259C7.84299 6.13969 8.29749 5.999 8.76286 5.999C9.22823 5.999 9.68272 6.13969 10.0667 6.40259C10.4507 6.6655 10.7462 7.03835 10.9144 7.47219C11.0826 7.90603 11.1158 8.38059 11.0094 8.83359C10.9031 9.28658 10.6622 9.69685 10.3185 10.0105C10.9485 10.2811 11.4963 10.7123 11.9073 11.2611ZM0.184609 5.90871C0.233095 5.94507 0.288269 5.97152 0.346981 5.98656C0.405693 6.0016 0.466792 6.00493 0.526791 5.99636C0.58679 5.98779 0.644513 5.96749 0.696664 5.93661C0.748816 5.90574 0.794375 5.8649 0.830739 5.81642C1.11017 5.44389 1.47251 5.14153 1.88906 4.93328C2.30561 4.72503 2.76493 4.61662 3.23065 4.61662C3.69637 4.61662 4.15569 4.72503 4.57224 4.93328C4.9888 5.14153 5.35113 5.44389 5.63057 5.81642C5.67355 5.87373 5.7293 5.92024 5.79338 5.95228C5.85747 5.98432 5.92813 6.001 5.99978 6.001C6.07143 6.001 6.1421 5.98432 6.20618 5.95228C6.27027 5.92024 6.32601 5.87373 6.369 5.81642C6.64843 5.44389 7.01077 5.14153 7.42732 4.93328C7.84387 4.72503 8.30319 4.61662 8.76891 4.61662C9.23463 4.61662 9.69396 4.72503 10.1105 4.93328C10.5271 5.14153 10.8894 5.44389 11.1688 5.81642C11.2052 5.8649 11.2508 5.90573 11.303 5.93659C11.3552 5.96745 11.413 5.98773 11.473 5.99628C11.533 6.00482 11.5941 6.00146 11.6529 5.98638C11.7116 5.97131 11.7668 5.94482 11.8152 5.90842C11.8637 5.87202 11.9046 5.82643 11.9354 5.77425C11.9663 5.72207 11.9866 5.66432 11.9951 5.60431C12.0037 5.54429 12.0003 5.48318 11.9852 5.42446C11.9702 5.36574 11.9437 5.31057 11.9073 5.26209C11.4986 4.71441 10.9536 4.28326 10.3265 4.01152C10.6703 3.69785 10.9111 3.28759 11.0175 2.83459C11.1238 2.38159 11.0907 1.90703 10.9225 1.47319C10.7542 1.03935 10.4587 0.666503 10.0748 0.403595C9.6908 0.140687 9.2363 0 8.77093 0C8.30556 0 7.85106 0.140687 7.4671 0.403595C7.08313 0.666503 6.78763 1.03935 6.61939 1.47319C6.45116 1.90703 6.41804 2.38159 6.52439 2.83459C6.63074 3.28759 6.87159 3.69785 7.21532 4.01152C6.7629 4.20705 6.35177 4.48678 6.00382 4.83581C5.65587 4.48678 5.24474 4.20705 4.79233 4.01152C5.13606 3.69785 5.3769 3.28759 5.48325 2.83459C5.5896 2.38159 5.55649 1.90703 5.38825 1.47319C5.22001 1.03935 4.92452 0.666503 4.54055 0.403595C4.15658 0.140687 3.70208 0 3.23671 0C2.77134 0 2.31684 0.140687 1.93287 0.403595C1.5489 0.666503 1.25341 1.03935 1.08517 1.47319C0.916934 1.90703 0.883816 2.38159 0.990166 2.83459C1.09652 3.28759 1.33736 3.69785 1.68109 4.01152C1.05107 4.28228 0.503205 4.71372 0.0923046 5.26266C0.0559398 5.31114 0.0294812 5.36631 0.0144395 5.42501C-0.000602239 5.48372 -0.0039325 5.54481 0.00463875 5.6048C0.01321 5.66479 0.033515 5.72251 0.0643943 5.77465C0.0952737 5.8268 0.136123 5.87235 0.184609 5.90871Z",
                        fill: "#C33C2E",
                      }),
                    })
                  : i.jsxs("svg", {
                      width: ".75rem",
                      height: ".75rem",
                      viewBox: "0 0 12 12",
                      fill: "none",
                      xmlns: "http://www.w3.org/2000/svg",
                      children: [
                        i.jsx("path", {
                          d: "M9.75 1.5H7.875C7.77554 1.5 7.68016 1.53951 7.60983 1.60983C7.53951 1.68016 7.5 1.77554 7.5 1.875V2.25H4.5V1.875C4.5 1.77554 4.46049 1.68016 4.39016 1.60983C4.31984 1.53951 4.22446 1.5 4.125 1.5H2.25C1.85218 1.5 1.47064 1.65804 1.18934 1.93934C0.908035 2.22064 0.75 2.60218 0.75 3V9C0.75 9.39782 0.908035 9.77936 1.18934 10.0607C1.47064 10.342 1.85218 10.5 2.25 10.5H9.75C10.1478 10.5 10.5294 10.342 10.8107 10.0607C11.092 9.77936 11.25 9.39782 11.25 9V3C11.25 2.60218 11.092 2.22064 10.8107 1.93934C10.5294 1.65804 10.1478 1.5 9.75 1.5ZM10.5 9C10.5 9.19891 10.421 9.38968 10.2803 9.53033C10.1397 9.67098 9.94891 9.75 9.75 9.75H2.25C2.05109 9.75 1.86032 9.67098 1.71967 9.53033C1.57902 9.38968 1.5 9.19891 1.5 9V3C1.5 2.80109 1.57902 2.61032 1.71967 2.46967C1.86032 2.32902 2.05109 2.25 2.25 2.25H3.75V2.625C3.75 2.72446 3.78951 2.81984 3.85983 2.89016C3.93016 2.96049 4.02554 3 4.125 3H7.875C7.97446 3 8.06984 2.96049 8.14016 2.89016C8.21049 2.81984 8.25 2.72446 8.25 2.625V2.25H9.75C9.94891 2.25 10.1397 2.32902 10.2803 2.46967C10.421 2.61032 10.5 2.80109 10.5 3V9Z",
                          fill: "#f63b3bff",
                        }),
                        i.jsx("path", {
                          d: "M6 4.125C5.70163 4.125 5.41248 4.21353 5.16872 4.37882C4.92495 4.54412 4.73789 4.7784 4.63161 5.05173C4.52534 5.32506 4.50502 5.62417 4.57388 5.9117C4.64273 6.19923 4.79752 6.46053 5.01641 6.66459C5.2353 6.86864 5.50952 7.00625 5.80896 7.06048C6.1084 7.11472 6.41913 7.08314 6.70166 6.97C6.98419 6.85686 7.22675 6.66701 7.39687 6.42188C7.56699 6.17675 7.65625 5.88542 7.65625 5.58594C7.65625 5.18551 7.49036 4.80162 7.19484 4.51853C6.89933 4.23543 6.49674 4.07813 6.07813 4.07813L6 4.125ZM6 6.375C5.8517 6.375 5.70684 6.33289 5.58332 6.25372C5.45981 6.17456 5.36308 6.06177 5.30476 5.92962C5.24644 5.79748 5.22906 5.65104 5.25491 5.50962C5.28075 5.36821 5.34862 5.23754 5.45083 5.13333C5.55304 5.02911 5.68499 4.95627 5.82768 4.92497C5.97036 4.89367 6.11784 4.90544 6.25305 4.95886C6.38826 5.01228 6.50511 5.10494 6.58856 5.22575C6.67201 5.34656 6.71875 5.48975 6.71875 5.63672C6.71875 5.83171 6.64131 6.01874 6.50417 6.15864C6.36704 6.29854 6.1783 6.375 5.98125 6.375H6Z",
                          fill: "#f63b3bff",
                        }),
                      ],
                    }),
            i.jsx("p", {
              className: `text-xs font-semibold uppercase truncate ${a === "chest" ? "text-[#ff4848ff]" : a === "hired" ? "text-[#67C32E]" : a === "fired" ? "text-[#C33C2E]" : "text-[#f63b3bff]"}`,
              children:
                a === "chest"
                  ? "BAÚ"
                  : a === "hired"
                    ? "CONTRATAÇÃO"
                    : a === "fired"
                      ? "DEMISSÃO"
                      : "CRAFT",
            }),
          ],
        }),
      }),
      i.jsx("p", {
        className:
          "text-white text-xs font-semibold w-[17.9688rem] uppercase truncate",
        children: c,
      }),
      i.jsx("p", {
        className:
          "text-white/65 text-xs font-semibold w-[17.9688rem] text-center uppercase truncate",
        children: d,
      }),
    ],
  });
}
function w8({ logs: r }) {
  return i.jsxs("div", {
    className: "w-full flex-1 flex flex-col gap-2 overflow-hidden",
    children: [
      i.jsxs("div", {
        className:
          "w-full h-8 bg-white/[.02] rounded-[.3125rem] px-4 flex items-center",
        children: [
          i.jsx("p", {
            className: "text-white/60 text-xs font-semibold w-[8rem]",
            children: "#",
          }),
          i.jsx("p", {
            className: "text-white/60 text-xs font-semibold w-[17.9688rem]",
            children: "NOME",
          }),
          i.jsx("p", {
            className: "text-white/60 text-xs font-semibold w-[17.9688rem]",
            children: "TIPO",
          }),
          i.jsx("p", {
            className: "text-white/60 text-xs font-semibold w-[17.9688rem]",
            children: "DESCRIÇÃO",
          }),
          i.jsx("p", {
            className:
              "text-white/60 text-xs font-semibold w-[17.9688rem] text-center",
            children: "DATA",
          }),
        ],
      }),
      i.jsx("div", {
        className: "w-full flex-1 flex flex-col gap-2 overflow-y-auto",
        children: r == null ? void 0 : r.map((s, a) => i.jsx(g8, { ...s }, a)),
      }),
    ],
  });
}
function y8({ currentPage: r, totalPages: s, onPageChange: a }) {
  return s <= 1
    ? null
    : i.jsxs("div", {
        className: "w-full flex items-center justify-center gap-2 pt-2",
        children: [
          i.jsx("button", {
            onClick: () => a(Math.max(r - 1, 1)),
            disabled: r === 1,
            className: ne(
              "flex items-center justify-center w-8 h-8 rounded-[.3125rem] transition-all",
              r === 1
                ? "bg-white/[.02] cursor-not-allowed opacity-40"
                : "bg-white/[.04] hover:bg-white/[.08] cursor-pointer",
            ),
            children: i.jsx("svg", {
              width: "6",
              height: "10",
              viewBox: "0 0 6 10",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: i.jsx("path", {
                d: "M5 9L1 5L5 1",
                stroke: "white",
                strokeWidth: "1.5",
                strokeLinecap: "round",
                strokeLinejoin: "round",
              }),
            }),
          }),
          Array.from({ length: s }, (c, d) => d + 1).map((c) => {
            const d = c === r;
            return !(Math.abs(c - r) <= 1) && !(c === 1 || c === s)
              ? c === r - 2 || c === r + 2
                ? i.jsx(
                    "span",
                    {
                      className: "text-white/40 text-xs font-bold px-1",
                      children: "...",
                    },
                    c,
                  )
                : null
              : i.jsx(
                  "button",
                  {
                    onClick: () => a(c),
                    className: ne(
                      "flex items-center justify-center w-8 h-8 rounded-[.3125rem] text-xs font-bold transition-all",
                      d
                        ? "bg-white/[.12] text-white"
                        : "bg-white/[.04] text-white/70 hover:bg-white/[.08] hover:text-white",
                    ),
                    children: c,
                  },
                  c,
                );
          }),
          i.jsx("button", {
            onClick: () => a(Math.min(r + 1, s)),
            disabled: r === s,
            className: ne(
              "flex items-center justify-center w-8 h-8 rounded-[.3125rem] transition-all",
              r === s
                ? "bg-white/[.02] cursor-not-allowed opacity-40"
                : "bg-white/[.04] hover:bg-white/[.08] cursor-pointer",
            ),
            children: i.jsx("svg", {
              width: "6",
              height: "10",
              viewBox: "0 0 6 10",
              fill: "none",
              xmlns: "http://www.w3.org/2000/svg",
              children: i.jsx("path", {
                d: "M1 1L5 5L1 9",
                stroke: "white",
                strokeWidth: "1.5",
                strokeLinecap: "round",
                strokeLinejoin: "round",
              }),
            }),
          }),
        ],
      });
}
const j8 = () => {
  const [r, s] = p.useState(""),
    [a, c] = p.useState([]),
    [d, m] = p.useState(null),
    [x, h] = p.useState(!1),
    [v, y] = p.useState(1),
    [M, j] = p.useState({ filters: [], totalPages: 10, currentPage: 1 }),
    b = 10,
    O = p.useMemo(
      () =>
        a.filter((T) => {
          const V = r.toLowerCase(),
            Z = T.name.toLowerCase().includes(V) || T.id.toString().includes(r),
            ee = d ? T.type === d : !0;
          return Z && ee;
        }),
      [a, r, d],
    ),
    H = p.useMemo(() => {
      const T = (v - 1) * b,
        V = T + b;
      return O.slice(T, V);
    }, [O, v]),
    N = p.useMemo(() => Math.ceil(O.length / b), [O]);
  (p.useEffect(() => {
    y(1);
  }, [r, d]),
    p.useEffect(() => {
      const T = (V) => {
        const Z = V.target;
        x && !Z.closest(".relative") && h(!1);
      };
      return (
        document.addEventListener("mousedown", T),
        () => {
          document.removeEventListener("mousedown", T);
        }
      );
    }, [x]),
    p.useEffect(() => {
      se("GetLogsData", null, {
        totalPages: 10,
        currentPage: 1,
        filters: [
          { label: "BAÚ", value: "chest" },
          { label: "CONTRATAÇÃO", value: "hired" },
          { label: "DEMISSÃO", value: "fired" },
          { label: "CRAFT", value: "craft" },
        ],
      }).then(j);
    }, []),
    p.useEffect(() => {
      const T = [
          "THUNDER",
          "FALCON",
          "VIPER",
          "EAGLE",
          "TIGER",
          "RAVEN",
          "PANTHER",
          "BLADE",
          "LYNX",
          "WOLF",
          "BULLET",
          "SMOKE",
          "DRAGON",
          "GHOST",
          "STORM",
          "SHADOW",
          "COBRA",
          "PHOENIX",
          "HAWK",
          "SMOKE2",
        ],
        V = [
          { name: "BAÚ", type: "chest" },
          { name: "CONTRATAÇÃO", type: "hired" },
          { name: "DEMISSÃO", type: "fired" },
          { name: "CRAFT", type: "craft" },
        ],
        Z = Array.from({ length: 50 }).map((ee, K) => {
          const Y = new Date(2025, 0, K + 1),
            de = String(Y.getMonth() + 1).padStart(2, "0"),
            Pe = String(Y.getDate()).padStart(2, "0"),
            st = `${Y.getFullYear()}-${de}-${Pe}`,
            Oe = V[K % V.length];
          let Le = "";
          return (
            Oe.type === "chest"
              ? (Le = `BAÚ ${Math.floor(K / 3) + 1} acessado por ${T[K % T.length]}`)
              : Oe.type === "hired"
                ? (Le = `Membro ${T[(K + 1) % T.length]} contratado`)
                : Oe.type === "fired"
                  ? (Le = `Membro ${T[(K + 2) % T.length]} demitido`)
                  : (Le = `Item craftado por ${T[(K + 3) % T.length]}`),
            {
              id: K + 1,
              name: Oe.name,
              type: Oe.type,
              description: Le,
              date: st,
            }
          );
        });
      se("GetLogs", { currentPage: v, selectedFilter: d }, Z).then(c);
    }, [d, v]));
  const k = () => {
      h(!x);
    },
    P = (T) => {
      (m(T), h(!1));
    };
  return i.jsxs("div", {
    className:
      "size-full flex flex-col gap-3 bg-white/[.01] border-[.0625rem] border-white/5 rounded-[.3125rem] p-4 overflow-hidden",
    children: [
      i.jsx(v8, {
        selectedFilter: d,
        isDropdownOpen: x,
        filters: M.filters,
        search: r,
        onFilterToggle: k,
        onFilterSelect: P,
        onSearchChange: s,
      }),
      i.jsx(w8, { logs: H }),
      i.jsx(y8, { currentPage: v, totalPages: N, onPageChange: y }),
    ],
  });
};
Fu.createRoot(document.getElementById("root")).render(
  i.jsx(z0.StrictMode, {
    children: i.jsx(b6, {
      children: i.jsx($6, {
        children: i.jsx(j9, {
          children: i.jsxs(k6, {
            children: [
              i.jsx(Vt, { path: "/", element: i.jsx(F9, {}) }),
              i.jsx(Vt, { path: "/logs", element: i.jsx(j8, {}) }),
              i.jsx(Vt, { path: "/members", element: i.jsx(V9, {}) }),
              i.jsx(Vt, { path: "/settings", element: i.jsx(G9, {}) }),
              i.jsx(Vt, { path: "/partners", element: i.jsx(q9, {}) }),
              i.jsx(Vt, { path: "/bank", element: i.jsx(l8, {}) }),
              i.jsx(Vt, { path: "/goals", element: i.jsx(f8, {}) }),
              i.jsx(Vt, { path: "/ranking", element: i.jsx(C8, {}) }),
            ],
          }),
        }),
      }),
    }),
  }),
);
