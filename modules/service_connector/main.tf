// Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.oci_provider["tenancy"]
}

resource "oci_sch_service_connector" "this" {
  for_each       = var.srv_connector_params
  compartment_id = var.compartments[each.value.comp_name]
  display_name   = each.value.display_name
  source {
    kind = lower(each.value.srv_connector_source_kind)
    cursor {
      kind = lower(each.value.srv_connector_source_kind) == "streaming" ? "streaming" : null
    }
    dynamic "log_sources" {
      itterator = ls
      for_each  = each.value.log_sources_params
      content {
        compartment_id = lower(each.value.srv_connector_source_kind) == "logging" ? var.compartments[ls.value.log_comp_name] : null
        log_group_id   = lower(each.value.srv_connector_source_kind) == "logging" ? var.log_group[ls.value.log_group_name] : null
        log_id         = lower(each.value.srv_connector_source_kind) == "logging" ? var.log_id[ls.value.log_name] : null
      }
    }
    stream_id = lower(each.value.srv_connector_source_kind) == "streaming" ? var.streaming[each.value.stream_name] : null
  }
  target {
    kind = each.value.srv_connector_target_kind

    batch_rollover_size_in_mbs = each.value.srv_connector_target_kind == "objectStorage" ? each.value.obj_batch_rollover_size_in_mbs : null
    batch_rollover_time_in_ms  = each.value.srv_connector_target_kind == "objectStorage" ? each.value.obj_batch_rollover_time_in_ms : null
    bucket                     = each.value.srv_connector_target_kind == "objectStorage" ? each.value.obj_target_bucket : null
    compartment_id             = each.value.srv_connector_target_kind == "monitoring" ? var.compartments[each.value.monitoring_compartment] : null
    function_id                = each.value.srv_connector_target_kind == "functions" ? var.functions[each.value.function_name] : null
    log_group_id               = each.value.srv_connector_target_kind == "loggingAnalytics" ? var.log_group[each.value.target_log_group] : null
    metric                     = each.value.srv_connector_target_kind == "monitoring" ? each.value.mon_target_metric : null
    metric_namespace           = each.value.srv_connector_target_kind == "monitoring" ? each.value.mon_target_metric_namespace : null
    namespace                  = each.value.srv_connector_target_kind == "objectStorage" ? data.oci_objectstorage_namespace.this.namespace : null
    stream_id                  = each.value.srv_connector_target_kind == "streaming" ? var.streaming[each.value.target_stream_name] : null
    topic_id                   = each.value.srv_connector_target_kind == "notifications" ? var.topics[each.value.target_topic_name] : null
  }

  dynamic "tasks" {
    itterator = tsk
    for_each  = tasks_params
    content {
      kind              = tsk.value.tasks_kind
      batch_size_in_kbs = tsk.value.task_batch_size_in_kbs
      batch_time_in_sec = tsk.value.task_batch_time_in_sec
      function_id       = var.functions[tsk.value.task_function_name]
    }
  }
}
