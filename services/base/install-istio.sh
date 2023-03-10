#!/bin/bash

kubectl create namespace istio-system

istioctl operator init

cat <<EOF | kubectl apply -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
  namespace: istio-system
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: 4
  profile: demo
  components:
    ingressGateways:
      - enabled: true
        name: istio-ingressgateway
        k8s:
          hpaSpec:
            maxReplicas: 10
            minReplicas: 5
          serviceAnnotations:
            service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
          affinity:
            podAntiAffinity:
              preferredDuringSchedulingIgnoredDuringExecution:
              - podAffinityTerm:
                  labelSelector:
                    matchLabels:
                      istio: ingressgateway
                  topologyKey: failure-domain.beta.kubernetes.io/zone
                weight: 1
          service:
            ports:
              - port: 15021
                targetPort: 15021
                name: status-port
              - port: 80
                targetPort: 8080
                nodePort: 31080
                name: http2
              - port: 443
                targetPort: 8443
                nodePort: 31443
                name: https
              - port: 32400
                targetPort: 31400
                nodePort: 32400
                name: tcp
              - port: 15443
                targetPort: 15443
                nodePort: 32443
                name: tls
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: http-compressor-v3
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      # Put same labels that will identify your application
      istio: ingressgateway
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: GATEWAY
        listener:
          filterChain:
            filter:
              name: envoy.filters.network.http_connection_manager
              subFilter:
                name: envoy.filters.http.router
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.compressor
          typed_config:
            # See https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/compressor_filter for full options
            '@type': type.googleapis.com/envoy.extensions.filters.http.compressor.v3.Compressor
            compressor_library:
              name: text_optimized
              compression_level: DEFAULT
              memory_level: 9
              window_bits: 15
              typed_config:
                '@type': type.googleapis.com/envoy.extensions.compression.gzip.compressor.v3.Gzip
            remove_accept_encoding_header: true
EOF

cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: proxy-protocol
  namespace: istio-system
spec:
  configPatches:
  - applyTo: LISTENER
    patch:
      operation: MERGE
      value:
        listener_filters:
        - name: envoy.listener.proxy_protocol
        - name: envoy.listener.tls_inspector
  workloadSelector:
    labels:
      istio: ingressgateway
EOF